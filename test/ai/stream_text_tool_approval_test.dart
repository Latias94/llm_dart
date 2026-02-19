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

  _TestChatResponse({this.text})
      : thinking = null,
        toolCalls = null,
        usage = null,
        providerMetadata = null;
}

void main() {
  group('StreamTextResult tool approval', () {
    test('exposes toolLoopBlockedState when emitted', () async {
      const toolCall = V3ToolCall(
        toolCallId: 'call1',
        toolName: 'calc',
        input: '{"x":1}',
      );

      final stepResult = GenerateTextResult(
        rawResponse: _TestChatResponse(text: 'Hello'),
        text: 'Hello',
        toolCalls: const [toolCall],
      );

      final blockedState = ToolLoopBlockedState(
        stepIndex: 0,
        stepResult: stepResult,
        toolCalls: const [toolCall],
        toolApprovalRequests: const [
          ToolApprovalRequest(approvalId: 'a1', toolCall: toolCall),
        ],
        steps: const <ToolLoopStep>[],
        messages: const <ChatMessage>[],
        prompt: null,
      );

      final upstream = Stream<LLMStreamPart>.fromIterable([
        const LLMTextStartPart(blockId: 't1'),
        const LLMTextDeltaPart('Hello', blockId: 't1'),
        const LLMTextEndPart('Hello', blockId: 't1'),
        LLMToolLoopBlockedPart(blockedState),
        LLMFinishPart(_TestChatResponse(text: 'Hello')),
      ]);

      final result = StreamTextResult.fromPartsStream(upstream);

      expect(await result.text, equals('Hello'));
      expect(await result.toolLoopBlockedState, same(blockedState));
      expect(await result.finalResult, isA<GenerateTextResult>());
      await result.done;
    });
  });
}
