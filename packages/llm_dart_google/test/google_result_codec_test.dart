import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  const codec = GoogleGenerateContentResultCodec();

  group('GoogleGenerateContentResultCodec', () {
    test('decodes reasoning, text, tool calls, files, and sources', () {
      final result = codec.decodeResponse({
        'responseId': 'resp_1',
        'modelVersion': 'gemini-3-pro-preview',
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': 'Plan first.',
                  'thought': true,
                  'thoughtSignature': 'sig_1',
                },
                {
                  'text': 'Hello from Google.',
                },
                {
                  'functionCall': {
                    'name': 'weather',
                    'args': {
                      'city': 'Hong Kong',
                    },
                  },
                  'thoughtSignature': 'sig_2',
                },
                {
                  'inlineData': {
                    'mimeType': 'image/png',
                    'data': 'AQID',
                  },
                },
              ],
              'role': 'model',
            },
            'finishReason': 'STOP',
            'finishMessage': 'Model generated function call(s).',
            'groundingMetadata': {
              'groundingChunks': [
                {
                  'web': {
                    'uri': 'https://example.com',
                    'title': 'Example',
                  },
                },
              ],
            },
            'safetyRatings': [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'probability': 'NEGLIGIBLE',
              },
            ],
          },
        ],
        'promptFeedback': {
          'safetyRatings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'probability': 'NEGLIGIBLE',
            },
          ],
        },
        'usageMetadata': {
          'promptTokenCount': 10,
          'candidatesTokenCount': 3,
          'thoughtsTokenCount': 5,
          'totalTokenCount': 18,
        },
      });

      expect(result.responseId, 'resp_1');
      expect(result.responseModelId, 'gemini-3-pro-preview');
      expect(result.text, 'Hello from Google.');
      expect(result.reasoningText, 'Plan first.');
      expect(result.finishReason, FinishReason.toolCalls);
      expect(result.rawFinishReason, 'STOP');
      expect(result.usage?.inputTokens, 10);
      expect(result.usage?.outputTokens, 8);
      expect(result.usage?.reasoningTokens, 5);

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      expect(toolCall.toolCall.toolName, 'weather');
      expect(
        toolCall.providerMetadata?.values['google'],
        {
          'thoughtSignature': 'sig_2',
        },
      );

      final file = result.content.whereType<FileContentPart>().single.file;
      expect(file.mediaType, 'image/png');
      expect(file.bytes, [1, 2, 3]);

      final source =
          result.content.whereType<SourceContentPart>().single.source;
      expect(source.kind, SourceReferenceKind.url);
      expect(source.uri, Uri.parse('https://example.com'));

      expect(
        result.providerMetadata?.values['google'],
        allOf(
          containsPair('finishMessage', 'Model generated function call(s).'),
          contains('groundingMetadata'),
          contains('usageMetadata'),
        ),
      );
    });

    test('decodes provider-executed code execution content', () {
      final result = codec.decodeResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'executableCode': {
                    'language': 'PYTHON',
                    'code': 'print("hi")',
                  },
                },
                {
                  'codeExecutionResult': {
                    'outcome': 'OUTCOME_OK',
                    'output': 'hi',
                  },
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });

      final toolCall = result.content.whereType<ToolCallContentPart>().single;
      final toolResult =
          result.content.whereType<ToolResultContentPart>().single;

      expect(toolCall.toolCall.toolName, 'code_execution');
      expect(toolCall.toolCall.providerExecuted, isTrue);
      expect(toolCall.toolCall.isDynamic, isTrue);
      expect(toolResult.toolResult.toolName, 'code_execution');
      expect(toolResult.toolResult.isDynamic, isTrue);
      expect(toolResult.toolResult.isError, isFalse);
    });

    test('decodes thought inline data into reasoning-file content', () {
      final result = codec.decodeResponse({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'inlineData': {
                    'mimeType': 'image/png',
                    'data': 'AQID',
                  },
                  'thought': true,
                  'thoughtSignature': 'sig_reasoning_file',
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });

      final reasoningFile =
          result.content.whereType<ReasoningFileContentPart>().single;
      expect(reasoningFile.file.mediaType, 'image/png');
      expect(reasoningFile.file.bytes, [1, 2, 3]);
      expect(
        reasoningFile.providerMetadata?.values['google'],
        {
          'thoughtSignature': 'sig_reasoning_file',
          'thought': true,
        },
      );
    });
  });
}
