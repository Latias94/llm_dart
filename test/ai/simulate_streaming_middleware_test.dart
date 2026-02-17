library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponseWithFinishReason {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  @override
  final LLMFinishReason? finishReason;

  const _FakeChatResponse({
    this.text,
    this.thinking,
    this.toolCalls,
    this.finishReason,
  }) : usage = null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _FakeNonStreamingModel extends ChatCapability {
  final ChatResponse response;

  _FakeNonStreamingModel(this.response);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return response;
  }
}

void main() {
  group('SimulateStreamingMiddleware', () {
    test('simulates parts-first streaming via generate fallback', () async {
      final inner = _FakeNonStreamingModel(
        _FakeChatResponse(
          thinking: 'think',
          text: 'hello',
          toolCalls: const [
            ToolCall(
              id: 'call_1',
              callType: 'function',
              function: FunctionCall(
                name: 'getWeather',
                arguments: '{"city":"SF"}',
              ),
            ),
          ],
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: 'stop',
          ),
        ),
      );

      final wrapped = wrapLanguageModelWithMiddleware(
        inner,
        middlewares: const [
          SimulateStreamingMiddleware(),
        ],
      );

      final result = streamText(
        model: wrapped,
        messages: [ChatMessage.user('hi')],
      );

      final partsFuture = result.fullStream.toList();

      expect(await result.text, equals('hello'));
      expect(await result.thinkingText, equals('think'));

      final parts = await partsFuture;
      expect(parts.whereType<LLMStreamStartPart>(), isNotEmpty);
      expect(parts.whereType<LLMResponseMetadataPart>(), isNotEmpty);
      expect(parts.whereType<LLMTextDeltaPart>(), isNotEmpty);
      expect(parts.whereType<LLMReasoningDeltaPart>(), isNotEmpty);
      expect(parts.whereType<LLMToolInputStartPart>(), isNotEmpty);
      expect(parts.whereType<LLMFinishPart>(), hasLength(1));
    });
  });
}
