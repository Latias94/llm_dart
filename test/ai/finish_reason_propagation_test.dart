import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeResponse implements ChatResponseWithFinishReason {
  @override
  String? get text => 'hi';

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;

  @override
  LLMFinishReason? get finishReason => const LLMFinishReason(
        unified: LLMUnifiedFinishReason.stop,
        raw: 'stop',
      );
}

class _FakeModel implements ChatCapability, ChatStreamPartsCapability {
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return _FakeResponse();
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) =>
      chatWithTools(messages, null, cancelToken: cancelToken);

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async =>
      'summary';

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) async* {
    yield const LLMTextDeltaPart('hi');
    yield LLMFinishPart(_FakeResponse());
  }
}

void main() {
  group('finishReason propagation (llm_dart_ai)', () {
    test('generateText exposes finishReason when available', () async {
      final result = await generateText(
        model: _FakeModel(),
        messages: [ChatMessage.user('x')],
      );

      expect(result.finishReason, isNotNull);
      expect(result.finishReason!.unified, equals(LLMUnifiedFinishReason.stop));
      expect(result.finishReason!.raw, equals('stop'));
    });

    test('streamChatParts finish part exposes finishReason when available',
        () async {
      final parts = await streamChatParts(
        model: _FakeModel(),
        messages: [ChatMessage.user('x')],
      ).toList();

      final finish = parts.whereType<LLMFinishPart>().single;
      expect(finish.finishReason, isNotNull);
      expect(
        finish.finishReason!.unified,
        equals(LLMUnifiedFinishReason.stop),
      );
      expect(finish.finishReason!.raw, equals('stop'));
    });
  });
}
