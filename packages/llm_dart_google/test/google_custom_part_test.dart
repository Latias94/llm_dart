import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:test/test.dart';

void main() {
  group('GoogleCustomPart', () {
    test('parses Google custom content parts into typed wrappers', () {
      final toolCall = GoogleToolCallReplay.fromToolCall(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'query': 'Dart SDK',
        },
        providerMetadata: const ProviderMetadata({
          'google': {
            'thoughtSignature': 'sig_srvtool_1',
          },
        }),
      );
      final toolResponse = GoogleToolResponseReplay.fromToolResponse(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [
              {
                'uri': 'https://dart.dev',
              },
            ],
          },
        },
      );
      final functionResponse = GoogleFunctionResponseReplay(
        toolCallId: 'call_google_2',
        toolName: 'render_chart',
        functionCallId: 'call_google_2',
        response: {
          'status': 'ok',
        },
        files: const [
          GeneratedFile(
            mediaType: 'image/png',
            filename: 'chart.png',
            data: FileBytesData.constBytes([1, 2, 3]),
          ),
        ],
      );

      final parsed = GoogleCustomPart.parseContentParts([
        toolCall.toCustomContentPart(),
        toolResponse.toCustomContentPart(),
        functionResponse.toCustomContentPart(),
        const CustomContentPart(
          kind: 'openai.compaction',
          data: {
            'id': 'cmp_1',
          },
        ),
      ]);

      expect(parsed, hasLength(3));
      expect(parsed[0], isA<GoogleToolCallCustomPart>());
      expect(parsed[1], isA<GoogleToolResponseCustomPart>());
      expect(parsed[2], isA<GoogleFunctionResponseCustomPart>());

      final parsedToolCall = parsed[0] as GoogleToolCallCustomPart;
      expect(parsedToolCall.isAssistantReplay, isTrue);
      expect(parsedToolCall.toolCallId, 'srvtool_1');
      expect(parsedToolCall.toolCall, {
        'id': 'srvtool_1',
        'toolType': 'google_search',
        'query': 'Dart SDK',
      });
      expect(
        parsedToolCall.providerMetadata?.values['google'],
        containsPair('thoughtSignature', 'sig_srvtool_1'),
      );

      final parsedToolResponse = parsed[1] as GoogleToolResponseCustomPart;
      expect(parsedToolResponse.isAssistantReplay, isTrue);
      expect(parsedToolResponse.toolResponse, {
        'id': 'srvtool_1',
        'toolType': 'google_search',
        'result': {
          'items': [
            {
              'uri': 'https://dart.dev',
            },
          ],
        },
      });

      final parsedFunctionResponse =
          parsed[2] as GoogleFunctionResponseCustomPart;
      expect(parsedFunctionResponse.isToolReplay, isTrue);
      expect(parsedFunctionResponse.functionCallId, 'call_google_2');
      expect(parsedFunctionResponse.response, {
        'status': 'ok',
      });
      expect(parsedFunctionResponse.files.single.filename, 'chart.png');
    });

    test('parses prompt parts, content parts, and events', () {
      final toolCall = GoogleToolCallReplay.fromToolCall(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'query': 'Dart SDK',
        },
      );
      final toolResponse = GoogleToolResponseReplay.fromToolResponse(
        {
          'id': 'srvtool_1',
          'toolType': 'google_search',
          'result': {
            'items': [],
          },
        },
      );
      final functionResponse = GoogleFunctionResponseReplay(
        toolCallId: 'call_google_2',
        toolName: 'render_chart',
        response: {
          'status': 'ok',
        },
      );

      expect(
        GoogleCustomPart.tryParsePromptPart(toolCall.toCustomPromptPart()),
        isA<GoogleToolCallCustomPart>(),
      );
      expect(
        GoogleCustomPart.tryParseContentPart(
            toolResponse.toCustomContentPart()),
        isA<GoogleToolResponseCustomPart>(),
      );
      expect(
        GoogleCustomPart.tryParseEvent(functionResponse.toCustomEvent()),
        isA<GoogleFunctionResponseCustomPart>(),
      );
    });

    test('returns null for non-Google custom payloads', () {
      expect(
        GoogleCustomPart.tryParseContentPart(
          const CustomContentPart(
            kind: 'openai.compaction',
            data: {
              'id': 'cmp_1',
            },
          ),
        ),
        isNull,
      );
    });
  });
}
