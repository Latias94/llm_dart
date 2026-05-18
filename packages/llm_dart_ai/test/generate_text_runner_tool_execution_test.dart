import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateText tool continuation', () {
    test('stops when no function tool executor is provided', () async {
      final continuation =
          await GenerateTextRunnerSupport.resolveFunctionToolContinuation(
        _step(
          content: [
            const ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'tool-1',
                toolName: 'weather',
              ),
            ),
          ],
        ),
        declaredToolNames: {'weather'},
        functionToolExecutor: null,
        runnerName: 'TestRunner',
      );

      expect(continuation.kind, GenerateTextToolContinuationKind.stop);
      expect(continuation.shouldContinue, isFalse);
      expect(continuation.executions, isEmpty);
    });

    test('stops when a provider approval request is waiting', () async {
      var executed = false;

      final continuation =
          await GenerateTextRunnerSupport.resolveFunctionToolContinuation(
        _step(
          content: const [
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'server-tool-1',
                toolName: 'computer',
                providerExecuted: true,
              ),
            ),
            ToolApprovalRequestContentPart(
              ToolApprovalRequestContent(
                approvalId: 'approval-1',
                toolCallId: 'server-tool-1',
              ),
            ),
          ],
        ),
        declaredToolNames: {'weather'},
        functionToolExecutor: (_) {
          executed = true;
          return const GenerateTextToolExecutionResult.output('unused');
        },
        runnerName: 'TestRunner',
      );

      expect(continuation.kind, GenerateTextToolContinuationKind.stop);
      expect(continuation.shouldContinue, isFalse);
      expect(executed, isFalse);
    });

    test('continues when the model already returned matching tool results',
        () async {
      var executed = false;

      final continuation =
          await GenerateTextRunnerSupport.resolveFunctionToolContinuation(
        _step(
          content: [
            const ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'tool-1',
                toolName: 'weather',
              ),
            ),
            ToolResultContentPart(
              ToolResultContent(
                toolCallId: 'tool-1',
                toolName: 'weather',
                output: 'cached',
              ),
            ),
          ],
        ),
        declaredToolNames: {'weather'},
        functionToolExecutor: (_) {
          executed = true;
          return const GenerateTextToolExecutionResult.output('unused');
        },
        runnerName: 'TestRunner',
      );

      expect(
        continuation.kind,
        GenerateTextToolContinuationKind.continueWithExecutions,
      );
      expect(continuation.shouldContinue, isTrue);
      expect(continuation.executions, isEmpty);
      expect(executed, isFalse);
    });

    test('executes unresolved declared client tool calls', () async {
      final continuation =
          await GenerateTextRunnerSupport.resolveFunctionToolContinuation(
        _step(
          content: const [
            ToolCallContentPart(
              ToolCallContent(
                toolCallId: 'tool-1',
                toolName: 'weather',
                input: {
                  'city': 'Tokyo',
                },
              ),
            ),
          ],
        ),
        declaredToolNames: {'weather'},
        functionToolExecutor: (request) {
          expect(request.toolCall.toolCallId, 'tool-1');
          return const GenerateTextToolExecutionResult.output({
            'forecast': 'sunny',
          });
        },
        runnerName: 'TestRunner',
      );

      expect(continuation.shouldContinue, isTrue);
      expect(continuation.executions, hasLength(1));
      expect(continuation.executions.single.result.output, {
        'forecast': 'sunny',
      });
    });

    test('rejects tool-calls finish without calls or approvals', () async {
      await expectLater(
        GenerateTextRunnerSupport.resolveFunctionToolContinuation(
          _step(content: const []),
          declaredToolNames: const {},
          functionToolExecutor: (_) =>
              const GenerateTextToolExecutionResult.output('unused'),
          runnerName: 'TestRunner',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('without tool calls'),
          ),
        ),
      );
    });
  });
}

GenerateTextStepResult _step({
  required List<ContentPart> content,
}) {
  return GenerateTextStepResult(
    stepNumber: 0,
    providerId: 'test-provider',
    modelId: 'test-model',
    request: GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('hello'),
      ],
    ),
    result: GenerateTextResult(
      content: content,
      finishReason: FinishReason.toolCalls,
    ),
  );
}
