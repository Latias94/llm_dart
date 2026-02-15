library;

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _FakeChatResponse implements ChatResponse {
  @override
  final String? text;

  const _FakeChatResponse({this.text});

  @override
  List<ToolCall>? get toolCalls => null;

  @override
  String? get thinking => null;

  @override
  UsageInfo? get usage => null;

  @override
  Map<String, dynamic>? get providerMetadata => null;
}

class _FakeChatModel extends ChatCapability
    implements ChatStreamPartsCapability {
  final List<LLMStreamPart> parts;

  _FakeChatModel(this.parts);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
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
  group('ensureBlockIdsPart (via streamChatParts)', () {
    test('synthesizes text-start when text-delta arrives without a start',
        () async {
      final model = _FakeChatModel(const [
        LLMTextDeltaPart('A'),
        LLMFinishPart(_FakeChatResponse(text: 'A')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final startIndex = parts.indexWhere((p) => p is LLMTextStartPart);
      final deltaIndex = parts.indexWhere((p) => p is LLMTextDeltaPart);
      expect(startIndex, isNonNegative);
      expect(deltaIndex, isNonNegative);
      expect(startIndex, lessThan(deltaIndex));

      final start = parts[startIndex] as LLMTextStartPart;
      final delta = parts[deltaIndex] as LLMTextDeltaPart;
      expect(start.blockId, isNotNull);
      expect(delta.blockId, equals(start.blockId));
      expect(delta.delta, equals('A'));
    });

    test(
        'synthesizes reasoning-start when reasoning-end arrives without a start',
        () async {
      final model = _FakeChatModel(const [
        LLMReasoningEndPart('done'),
        LLMFinishPart(_FakeChatResponse(text: 'ok')),
      ]);

      final parts = await streamChatParts(
        model: model,
        messages: [ChatMessage.user('hi')],
      ).toList();

      final startIndex = parts.indexWhere((p) => p is LLMReasoningStartPart);
      final endIndex = parts.indexWhere((p) => p is LLMReasoningEndPart);
      expect(startIndex, isNonNegative);
      expect(endIndex, isNonNegative);
      expect(startIndex, lessThan(endIndex));

      final start = parts[startIndex] as LLMReasoningStartPart;
      final end = parts[endIndex] as LLMReasoningEndPart;
      expect(start.blockId, isNotNull);
      expect(end.blockId, equals(start.blockId));
      expect(end.thinking, equals('done'));
    });
  });
}
