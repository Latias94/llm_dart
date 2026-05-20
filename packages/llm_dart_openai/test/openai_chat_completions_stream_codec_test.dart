import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_openai/src/chat_completions/openai_chat_completions_codec.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAIChatCompletionsCodec stream decoding', () {
    test('maps reasoning, text, tool calls, and finish events', () {
      const codec = OpenAIChatCompletionsCodec(providerNamespace: 'deepseek');
      final state = OpenAIChatCompletionsStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'id': 'chatcmpl_1',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'deepseek-reasoner',
          'choices': [
            {
              'index': 0,
              'delta': {
                'role': 'assistant',
                'reasoning_content': 'Plan',
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_1',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'deepseek-reasoner',
          'choices': [
            {
              'index': 0,
              'delta': {
                'content': 'Hello',
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_1',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'deepseek-reasoner',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'type': 'function',
                    'function': {
                      'name': 'weather',
                      'arguments': '{"city":"Sh',
                    },
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_1',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'deepseek-reasoner',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'function': {
                      'arguments': 'anghai"}',
                    },
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_1',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'deepseek-reasoner',
          'system_fingerprint': 'fp_1',
          'choices': [
            {
              'index': 0,
              'delta': const {},
              'finish_reason': 'tool_calls',
            },
          ],
          'usage': {
            'prompt_tokens': 12,
            'completion_tokens': 8,
            'total_tokens': 20,
            'completion_tokens_details': {
              'reasoning_tokens': 3,
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final responseMetadata = events.whereType<ResponseMetadataEvent>().single;
      expect(responseMetadata.responseId, 'chatcmpl_1');
      expect(responseMetadata.modelId, 'deepseek-reasoner');
      expect(
        responseMetadata.providerMetadata?.values['deepseek'],
        containsPair('responseId', 'chatcmpl_1'),
      );

      expect(events.whereType<ReasoningStartEvent>().single.id, 'reasoning_0');
      expect(events.whereType<ReasoningDeltaEvent>().single.delta, 'Plan');
      expect(events.whereType<ReasoningEndEvent>().single.id, 'reasoning_0');

      expect(events.whereType<TextStartEvent>().single.id, 'text_0');
      expect(events.whereType<TextDeltaEvent>().single.delta, 'Hello');
      expect(events.whereType<TextEndEvent>().single.id, 'text_0');

      final toolInputStart = events.whereType<ToolInputStartEvent>().single;
      expect(toolInputStart.toolCallId, 'call_1');
      expect(toolInputStart.toolName, 'weather');
      expect(
        events.whereType<ToolInputDeltaEvent>().map((event) => event.delta),
        ['{"city":"Sh', 'anghai"}'],
      );
      expect(events.whereType<ToolInputEndEvent>().single.toolCallId, 'call_1');

      final toolCall = events.whereType<ToolCallEvent>().single.toolCall;
      expect(toolCall.toolCallId, 'call_1');
      expect(toolCall.toolName, 'weather');
      expect(
        toolCall.input,
        {
          'city': 'Shanghai',
        },
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.rawFinishReason, 'tool_calls');
      expect(finish.usage?.reasoningTokens, 3);
      expect(finish.usage?.totalTokens, 20);
      expect(
        finish.providerMetadata?.values['deepseek'],
        allOf(
          containsPair('responseId', 'chatcmpl_1'),
          containsPair('systemFingerprint', 'fp_1'),
        ),
      );
    });

    test('maps xAI citation arrays to shared source events without duplicates',
        () {
      const codec = OpenAIChatCompletionsCodec(providerNamespace: 'xai');
      final state = OpenAIChatCompletionsStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'id': 'chatcmpl_xai_1',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'choices': [
            {
              'index': 0,
              'delta': {
                'content': 'Latest summary',
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_xai_1',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'citations': [
            'https://example.com/news',
          ],
          'choices': [
            {
              'index': 0,
              'delta': const {},
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_xai_1',
          'object': 'chat.completion.chunk',
          'created': 1710000200,
          'model': 'grok-3',
          'citations': [
            'https://example.com/news',
          ],
          'choices': [
            {
              'index': 0,
              'delta': const {},
              'finish_reason': 'stop',
            },
          ],
          'usage': {
            'prompt_tokens': 4,
            'completion_tokens': 3,
            'total_tokens': 7,
            'completion_tokens_details': {
              'reasoning_tokens': 0,
            },
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      final sources =
          events.whereType<SourceEvent>().map((event) => event.source).toList();
      expect(sources, hasLength(1));
      expect(sources.single.sourceId, 'https://example.com/news');
      expect(sources.single.kind, SourceReferenceKind.url);
      expect(
        sources.single.providerMetadata?.values['xai'],
        allOf(
          containsPair('responseId', 'chatcmpl_xai_1'),
          containsPair('citationIndex', 0),
        ),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.stop);
      expect(finish.usage?.totalTokens, 7);
    });

    test('maps malformed tool arguments to tool input errors', () {
      const codec = OpenAIChatCompletionsCodec();
      final state = OpenAIChatCompletionsStreamState();
      final events = <LanguageModelStreamEvent>[];

      for (final chunk in <Map<String, Object?>>[
        {
          'id': 'chatcmpl_invalid_tool',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'gpt-4.1-mini',
          'choices': [
            {
              'index': 0,
              'delta': {
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call_1',
                    'type': 'function',
                    'function': {
                      'name': 'weather',
                      'arguments': '{"city":',
                    },
                  },
                ],
              },
              'finish_reason': null,
            },
          ],
        },
        {
          'id': 'chatcmpl_invalid_tool',
          'object': 'chat.completion.chunk',
          'created': 1710000000,
          'model': 'gpt-4.1-mini',
          'choices': [
            {
              'index': 0,
              'delta': const {},
              'finish_reason': 'tool_calls',
            },
          ],
          'usage': {
            'prompt_tokens': 1,
            'completion_tokens': 1,
            'total_tokens': 2,
          },
        },
      ]) {
        events.addAll(codec.decodeStreamChunk(chunk, state));
      }

      expect(
          events.whereType<ToolInputStartEvent>().single.toolCallId, 'call_1');
      expect(events.whereType<ToolInputDeltaEvent>().single.delta, '{"city":');
      expect(events.whereType<ToolInputEndEvent>(), isEmpty);
      expect(events.whereType<ToolCallEvent>(), isEmpty);

      final toolInputError = events.whereType<ToolInputErrorEvent>().single;
      expect(toolInputError.toolCallId, 'call_1');
      expect(toolInputError.toolName, 'weather');
      expect(toolInputError.input, '{"city":');
      expect(
        toolInputError.errorText,
        contains('Invalid JSON tool arguments for "weather"'),
      );

      final finish = events.whereType<FinishEvent>().single;
      expect(finish.finishReason, FinishReason.toolCalls);
      expect(finish.usage?.totalTokens, 2);
    });

    test('maps top-level error payloads to ErrorEvent', () {
      const codec = OpenAIChatCompletionsCodec();
      final state = OpenAIChatCompletionsStreamState();

      final events = codec.decodeStreamChunk(
        {
          'error': {
            'type': 'server_error',
            'message': 'upstream failed',
          },
        },
        state,
      ).toList();

      expect(events, hasLength(1));
      expect(events.single, isA<ErrorEvent>());
      final error = (events.single as ErrorEvent).error;
      expect(error.kind, ModelErrorKind.provider);
      expect(error.code, 'server_error');
      expect(error.message, 'upstream failed');
    });
  });
}
