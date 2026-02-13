import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:test/test.dart';

class _TestChatResponse extends ChatResponse {
  @override
  final String? text;

  @override
  final String? thinking;

  @override
  final List<ToolCall>? toolCalls;

  @override
  final UsageInfo? usage;

  @override
  final Map<String, dynamic>? providerMetadata;

  _TestChatResponse({this.text, this.thinking})
      : toolCalls = null,
        usage = null,
        providerMetadata = null;
}

void main() {
  group('StreamTextResult textStream', () {
    test('yields text deltas in order', () async {
      final upstream = Stream<LLMStreamPart>.fromIterable([
        const LLMTextStartPart(blockId: 't1'),
        const LLMTextDeltaPart('Hello', blockId: 't1'),
        const LLMTextDeltaPart(', ', blockId: 't1'),
        const LLMTextDeltaPart('world', blockId: 't1'),
        const LLMTextEndPart('Hello, world', blockId: 't1'),
        LLMFinishPart(
          _TestChatResponse(text: 'Hello, world'),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: null,
          ),
        ),
      ]);

      final result = StreamTextResult.fromPartsStream(upstream);
      final deltas = await result.textStream.toList();
      expect(deltas.join(), equals('Hello, world'));
      await result.done;
    });

    test('yields reasoning deltas in order', () async {
      final upstream = Stream<LLMStreamPart>.fromIterable([
        const LLMReasoningStartPart(blockId: 'r1'),
        const LLMReasoningDeltaPart('a', blockId: 'r1'),
        const LLMReasoningDeltaPart('b', blockId: 'r1'),
        const LLMReasoningEndPart('ab', blockId: 'r1'),
        LLMFinishPart(
          _TestChatResponse(thinking: 'ab'),
          finishReason: const LLMFinishReason(
            unified: LLMUnifiedFinishReason.stop,
            raw: null,
          ),
        ),
      ]);

      final result = StreamTextResult.fromPartsStream(upstream);
      final deltas = await result.reasoningStream.toList();
      expect(deltas.join(), equals('ab'));
      await result.done;
    });
  });
}
