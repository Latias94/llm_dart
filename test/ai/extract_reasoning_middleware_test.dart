library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponseWithAssistantMessage {
  @override
  final String? text;

  const _FakeChatResponse(this.text);

  @override
  ChatMessage get assistantMessage => ChatMessage.assistant(text ?? '');

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

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

class _FakeStreamingModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final Stream<LLMStreamPart> parts;

  _FakeStreamingModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    throw UnsupportedError('not used');
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      parts;
}

void main() {
  group('ExtractReasoningMiddleware', () {
    test('extracts <think> in non-streaming text', () async {
      final model = wrapLanguageModelWithMiddleware(
        _FakeNonStreamingModel(
          _FakeChatResponse('<think>analyzing</think>Here'),
        ),
        middlewares: const [
          ExtractReasoningMiddleware(tagName: 'think'),
        ],
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      expect(result.text, equals('Here'));
      expect(result.thinking, equals('analyzing'));
      expect(result.responseMessages.single.content, equals('Here'));
    });

    test('startWithReasoning extracts when opening tag is missing', () async {
      final model = wrapLanguageModelWithMiddleware(
        _FakeNonStreamingModel(
          _FakeChatResponse('analyzing</think>Here'),
        ),
        middlewares: const [
          ExtractReasoningMiddleware(
            tagName: 'think',
            startWithReasoning: true,
          ),
        ],
      );

      final result = await generateText(
        model: model,
        messages: [ChatMessage.user('hi')],
      );

      expect(result.text, equals('Here'));
      expect(result.thinking, equals('analyzing'));
    });

    test('extracts <think> in streaming text deltas', () async {
      final wrapped = wrapLanguageModelWithMiddleware(
        _FakeStreamingModel(
          Stream<LLMStreamPart>.fromIterable([
            const LLMTextStartPart(blockId: '1'),
            const LLMTextDeltaPart('<think>analy', blockId: '1'),
            const LLMTextDeltaPart('zing</think>Hi', blockId: '1'),
            const LLMTextEndPart('<think>analyzing</think>Hi', blockId: '1'),
            LLMFinishPart(const _FakeChatResponse('ok')),
          ]),
        ),
        middlewares: const [
          ExtractReasoningMiddleware(tagName: 'think'),
        ],
      );

      final result = streamText(
        model: wrapped,
        messages: [ChatMessage.user('hi')],
      );

      final fullStreamFuture = result.fullStream.toList();
      expect(await result.text, equals('Hi'));
      expect(await result.thinkingText, equals('analyzing'));

      final parts = await fullStreamFuture;
      final combinedText =
          parts.whereType<LLMTextDeltaPart>().map((p) => p.delta).join();
      final combinedReasoning =
          parts.whereType<LLMReasoningDeltaPart>().map((p) => p.delta).join();
      expect(combinedText, equals('Hi'));
      expect(combinedReasoning, equals('analyzing'));
    });
  });
}
