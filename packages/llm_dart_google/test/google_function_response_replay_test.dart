import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleFunctionResponseReplay', () {
    test('round-trips through custom prompt parts and preserves files', () {
      final replay = GoogleFunctionResponseReplay(
        toolCallId: 'call_google_2',
        toolName: 'render_chart',
        functionCallId: 'call_google_2',
        response: {
          'status': 'ok',
        },
        files: [
          const GeneratedFile(
            mediaType: 'image/png',
            filename: 'chart.png',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
          GeneratedFile(
            mediaType: 'application/pdf',
            filename: 'quote.pdf',
            data: FileUrlData(Uri.parse('https://example.com/quote.pdf')),
          ),
          const GeneratedFile(
            mediaType: 'application/pdf',
            filename: 'uploaded.pdf',
            data: FileProviderReferenceData(
              ProviderReference({
                'google':
                    'https://generativelanguage.googleapis.com/v1beta/files/uploaded',
              }),
            ),
          ),
        ],
        extraFunctionResponseFields: const {
          'source': 'local-cache',
        },
      );

      final promptPart = replay.toCustomPromptPart();
      final parsed =
          GoogleFunctionResponseReplay.tryParsePromptPart(promptPart);

      expect(parsed, isNotNull);
      expect(parsed!.toolCallId, 'call_google_2');
      expect(parsed.toolName, 'render_chart');
      expect(parsed.functionCallId, 'call_google_2');
      expect(parsed.response, {
        'status': 'ok',
      });
      expect(parsed.files, hasLength(3));
      expect(parsed.files.first.bytes, [1, 2, 3]);
      expect(
        parsed.files[1].uri,
        Uri.parse('https://example.com/quote.pdf'),
      );
      expect(
        parsed.files.last.uri,
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/files/uploaded',
        ),
      );
      expect(
        parsed.providerMetadata?.values['google'],
        {
          'functionCallId': 'call_google_2',
        },
      );
      expect(parsed.toJson(), replay.toJson());
    });

    test(
        'builds from ContentToolOutput with text, json, files, and custom data',
        () {
      final replay = GoogleFunctionResponseReplay.fromToolOutput(
        toolCallId: 'call_google_4',
        toolName: 'render_report',
        toolOutput: ContentToolOutput(
          parts: [
            const TextToolOutputContentPart('Report ready'),
            const JsonToolOutputContentPart({
              'summary': 'ok',
            }),
            const FileToolOutputContentPart(
              mediaType: 'image/png',
              filename: 'chart.png',
              data: FileBytesData.constBytes([1, 2, 3]),
            ),
            const FileToolOutputContentPart(
              mediaType: 'text/plain',
              filename: 'notes.txt',
              data: FileTextData('hello'),
            ),
            const CustomToolOutputContentPart(
              kind: 'demo.custom',
              data: {
                'flag': true,
              },
            ),
          ],
        ),
        functionCallId: 'call_google_4',
        providerMetadata: const ProviderMetadata({
          'google': {
            'resultTag': 'tool-output',
          },
        }),
      );

      expect(
        replay.response,
        {
          'name': 'render_report',
          'content':
              'Report ready\n{"type":"json","value":{"summary":"ok"}}\n{"type":"custom","kind":"demo.custom","data":{"flag":true}}',
        },
      );
      expect(
        replay.functionResponse,
        {
          'id': 'call_google_4',
          'name': 'render_report',
          'response': {
            'name': 'render_report',
            'content':
                'Report ready\n{"type":"json","value":{"summary":"ok"}}\n{"type":"custom","kind":"demo.custom","data":{"flag":true}}',
          },
          'parts': [
            {
              'inlineData': {
                'mimeType': 'image/png',
                'data': 'AQID',
                'displayName': 'chart.png',
              },
            },
            {
              'inlineData': {
                'mimeType': 'text/plain',
                'data': base64Encode(utf8.encode('hello')),
                'displayName': 'notes.txt',
              },
            },
          ],
        },
      );
      expect(replay.files, hasLength(2));
      expect(replay.files[0].bytes, [1, 2, 3]);
      expect(replay.files[1].bytes, utf8.encode('hello'));
      expect(
        replay.providerMetadata?.values['google'],
        containsPair('functionCallId', 'call_google_4'),
      );
      expect(
        replay.providerMetadata?.values['google'],
        containsPair('resultTag', 'tool-output'),
      );
    });

    test('encodes data URL files as inlineData function response parts', () {
      final replay = GoogleFunctionResponseReplay.fromToolOutput(
        toolCallId: 'call_google_6',
        toolName: 'inspect_image',
        toolOutput: ContentToolOutput(
          parts: [
            FileToolOutputContentPart(
              mediaType: 'application/octet-stream',
              filename: 'image.png',
              data: FileUrlData(
                Uri.parse('data:image/png;base64,AQID'),
              ),
            ),
          ],
        ),
      );

      expect(
        replay.functionResponse,
        {
          'name': 'inspect_image',
          'response': {
            'name': 'inspect_image',
            'content': 'Tool executed successfully.',
          },
          'parts': [
            {
              'inlineData': {
                'mimeType': 'image/png',
                'data': 'AQID',
                'displayName': 'image.png',
              },
            },
          ],
        },
      );
      expect(replay.files.single.mediaType, 'image/png');
      expect(replay.files.single.bytes, [1, 2, 3]);
    });

    test('rejects mismatched tool names in replay payloads', () {
      expect(
        () => GoogleFunctionResponseReplay.fromJson({
          'schema': GoogleFunctionResponseReplay.schema,
          'replayRole': 'tool',
          'toolCallId': 'call_google_3',
          'toolName': 'weather',
          'functionResponse': {
            'name': 'different_tool',
            'response': {
              'temperature': 28,
            },
          },
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('functionResponse.name'),
          ),
        ),
      );
    });
  });
}
