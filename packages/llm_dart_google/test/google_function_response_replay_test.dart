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
            bytes: [1, 2, 3],
          ),
          GeneratedFile(
            mediaType: 'application/pdf',
            filename: 'quote.pdf',
            uri: Uri.parse('https://example.com/quote.pdf'),
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
