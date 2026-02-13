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
  group('StreamTextResult tool approval', () {
    test('completes finalResult with blocked state when approval required',
        () async {
      const toolCall = ToolCall(
        id: 'call1',
        callType: 'function',
        function: FunctionCall(name: 'calc', arguments: '{"x":1}'),
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
        toolCallsNeedingApproval: const [toolCall],
        steps: const <ToolLoopStep>[],
        messages: const <ChatMessage>[],
        prompt: null,
      );

      final upstream = Stream<LLMStreamPart>.fromIterable([
        const LLMTextStartPart(blockId: 't1'),
        const LLMTextDeltaPart('Hello', blockId: 't1'),
        const LLMTextEndPart('Hello', blockId: 't1'),
        LLMErrorPart(ToolApprovalRequiredError(state: blockedState)),
      ]);

      final result = StreamTextResult.fromPartsStream(upstream);

      expect(await result.text, equals('Hello'));
      final finalResult = await result.finalResult;
      expect(identical(finalResult, stepResult), isTrue);
      await result.done;
    });
  });
}

