library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  final Map<String, dynamic>? _providerMetadata;

  const _FakeChatResponse({
    this.text,
    Map<String, dynamic>? providerMetadata,
  })  : thinking = null,
        toolCalls = null,
        usage = null,
        _providerMetadata = providerMetadata;

  @override
  Map<String, dynamic>? get providerMetadata => _providerMetadata;
}

class _PartsOnlyChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _PartsOnlyChatModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    throw UnsupportedError('chatWithTools not used in this test');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    for (final part in parts) {
      yield part;
    }
  }
}

void main() {
  group('Tool loop safety', () {
    test('does not execute non-function LLMToolCall parts', () async {
      var handlerCalls = 0;

      final model = _PartsOnlyChatModel([
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hello'),
        LLMToolCallStartPart(
          const V3ToolCall(
            toolCallId: 'call_provider_1',
            toolName: '',
            input: '{}',
          ),
        ),
        const LLMToolCallEndPart('call_provider_1'),
        const LLMTextEndPart('Hello'),
        const LLMFinishPart(
          _FakeChatResponse(
            providerMetadata: {
              'openai': {'id': 'resp_1'}
            },
          ),
        ),
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'web_search': (input, options) async {
            handlerCalls++;
            return {'ok': true};
          },
        },
        maxSteps: 2,
      ).toList();

      expect(handlerCalls, equals(0));
      expect(parts.whereType<LLMToolResultPart>(), isEmpty);
      expect(parts.whereType<LLMToolCallStartPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });

    test('provider tool parts never trigger local tool execution', () async {
      var handlerCalls = 0;

      final model = _PartsOnlyChatModel([
        const LLMTextStartPart(),
        const LLMTextDeltaPart('Hi'),
        const LLMProviderToolCallPart(
          toolCallId: 'ws_1',
          toolName: 'web_search',
          input: {'query': 'x'},
        ),
        const LLMProviderToolResultPart(
          toolCallId: 'ws_1',
          toolName: 'web_search',
          result: {'ok': true},
        ),
        const LLMTextEndPart('Hi'),
        const LLMFinishPart(
          _FakeChatResponse(
            text: 'Hi',
            providerMetadata: {
              'xai.responses': {'id': 'resp_1'}
            },
          ),
        ),
      ]);

      final parts = await streamToolLoopParts(
        model: model,
        messages: [ChatMessage.user('hi')],
        toolHandlers: {
          'web_search': (input, options) async {
            handlerCalls++;
            return {'ok': true};
          },
        },
        maxSteps: 2,
      ).toList();

      expect(handlerCalls, equals(0));
      expect(parts.whereType<LLMToolResultPart>(), isEmpty);
      expect(parts.whereType<LLMProviderToolCallPart>(), hasLength(1));
      expect(parts.whereType<LLMProviderToolResultPart>(), hasLength(1));
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
