import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
import 'package:test/test.dart';

void main() {
  const codec = GoogleGenerateContentStreamCodec();

  group('GoogleGenerateContentStreamCodec', () {
    test('maps text, reasoning, tool calls, sources, and finish events', () {
      final state = GoogleGenerateContentStreamState();
      final events = <TextStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'responseId': 'resp_1',
          'modelVersion': 'gemini-3-pro-preview',
          'usageMetadata': {
            'promptTokenCount': 5,
            'candidatesTokenCount': 1,
            'totalTokenCount': 6,
          },
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Hello ',
                  },
                ],
              },
            },
          ],
        },
        {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': 'Plan',
                    'thought': true,
                    'thoughtSignature': 'sig_1',
                  },
                ],
              },
            },
          ],
        },
        {
          'usageMetadata': {
            'promptTokenCount': 5,
            'candidatesTokenCount': 3,
            'thoughtsTokenCount': 4,
            'totalTokenCount': 12,
          },
          'promptFeedback': {
            'safetyRatings': [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'probability': 'NEGLIGIBLE',
              },
            ],
          },
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'functionCall': {
                      'name': 'weather',
                      'args': {
                        'city': 'Hong Kong',
                      },
                    },
                    'thoughtSignature': 'sig_2',
                  },
                ],
              },
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
              'finishReason': 'STOP',
              'finishMessage': 'Model generated function call(s).',
              'safetyRatings': [
                {
                  'category': 'HARM_CATEGORY_HARASSMENT',
                  'probability': 'NEGLIGIBLE',
                },
              ],
            },
          ],
        },
      ]) {
        events.addAll(codec.decodeChunk(chunk, state));
      }

      expect(events.first, isA<ResponseMetadataEvent>());
      expect(events.whereType<TextStartEvent>().single.id, '0');
      expect(events.whereType<TextDeltaEvent>().first.delta, 'Hello ');
      expect(events.whereType<TextEndEvent>().single.id, '0');
      expect(events.whereType<ReasoningStartEvent>().single.id, '1');
      expect(events.whereType<ReasoningDeltaEvent>().single.delta, 'Plan');
      expect(events.whereType<ReasoningEndEvent>().single.id, '1');

      final toolInputStart = events.whereType<ToolInputStartEvent>().single;
      expect(toolInputStart.toolName, 'weather');
      final toolInputDelta = events.whereType<ToolInputDeltaEvent>().single;
      expect(toolInputDelta.delta, '{"city":"Hong Kong"}');
      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Hong Kong',
        },
      );

      final source = events.whereType<SourceEvent>().single.source;
      expect(source.uri, Uri.parse('https://example.com'));

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'STOP');
      expect(finish.usage?.totalTokens, 12);
      expect(
        finish.providerMetadata?.values['google'],
        allOf(
          containsPair('finishMessage', 'Model generated function call(s).'),
          contains('groundingMetadata'),
          contains('promptFeedback'),
        ),
      );
    });

    test('maps provider-executed code execution events', () {
      final state = GoogleGenerateContentStreamState();
      final events = codec.decodeChunk(
        {
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
        },
        state,
      ).toList();

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      final toolResult = events.whereType<ToolResultEvent>().single.toolResult;

      expect(toolCall.toolName, 'code_execution');
      expect(toolCall.providerExecuted, isTrue);
      expect(toolCall.isDynamic, isTrue);
      expect(toolResult.toolName, 'code_execution');
      expect(toolResult.isDynamic, isTrue);
      expect(toolResult.isError, isFalse);
    });
  });
}
