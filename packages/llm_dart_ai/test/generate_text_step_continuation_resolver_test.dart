import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_ai/src/model/generate_text_step_continuation_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextStepContinuationResolver', () {
    test('finishes non-tool step and stops without replaying prompt', () async {
      final prompt = [
        UserPromptMessage.text('hello'),
      ];
      final finishedSteps = <GenerateTextStepResult>[];
      final resolver = GenerateTextStepContinuationResolver(
        declaredToolNames: const {},
        functionToolExecutor: null,
        stopConditions: const [],
        runnerName: 'TestRunner',
      );

      final decision = await resolver.resolve(
        step: _textStep(),
        promptHistory: prompt,
        finishStep: (step) {
          finishedSteps.add(step);
          return finishedSteps;
        },
      );

      expect(decision.shouldContinue, isFalse);
      expect(decision.promptHistory, prompt);
      expect(finishedSteps, hasLength(1));
    });

    test('adds tool executions before evaluating stop conditions', () async {
      final prompt = [
        UserPromptMessage.text('weather'),
      ];
      final finishedSteps = <GenerateTextStepResult>[];
      var stopConditionSawToolResult = false;
      final resolver = GenerateTextStepContinuationResolver(
        declaredToolNames: {'weather'},
        functionToolExecutor: (_) =>
            const GenerateTextToolExecutionResult.output('sunny'),
        stopConditions: [
          (context) {
            stopConditionSawToolResult =
                context.steps.single.toolResults.single.output == 'sunny';
            return true;
          },
        ],
        runnerName: 'TestRunner',
      );

      final decision = await resolver.resolve(
        step: _toolStep(),
        promptHistory: prompt,
        finishStep: (step) {
          finishedSteps.add(step);
          return finishedSteps;
        },
      );

      expect(decision.shouldContinue, isFalse);
      expect(stopConditionSawToolResult, isTrue);
      expect(finishedSteps.single.toolResults.single.output, 'sunny');
    });

    test('uses custom tool execution applier for stream projections', () async {
      final prompt = [
        UserPromptMessage.text('weather'),
      ];
      final finishedSteps = <GenerateTextStepResult>[];
      var appliedExecutionCount = 0;
      final resolver = GenerateTextStepContinuationResolver(
        declaredToolNames: {'weather'},
        functionToolExecutor: (_) =>
            const GenerateTextToolExecutionResult.output('sunny'),
        stopConditions: const [],
        runnerName: 'TestRunner',
      );

      final decision = await resolver.resolve(
        step: _toolStep(),
        promptHistory: prompt,
        applyToolExecutions: (step, executions) {
          appliedExecutionCount = executions.length;
          return GenerateTextRunnerSupport.addToolExecutionsToStep(
            step,
            executions,
          );
        },
        finishStep: (step) {
          finishedSteps.add(step);
          return finishedSteps;
        },
      );

      expect(appliedExecutionCount, 1);
      expect(decision.shouldContinue, isTrue);
      expect(decision.promptHistory, hasLength(3));
      expect(finishedSteps.single.toolResults.single.output, 'sunny');
    });
  });
}

GenerateTextStepResult _textStep() {
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
      content: const [
        TextContentPart('hello'),
      ],
      finishReason: FinishReason.stop,
    ),
  );
}

GenerateTextStepResult _toolStep() {
  return GenerateTextStepResult(
    stepNumber: 0,
    providerId: 'test-provider',
    modelId: 'test-model',
    request: GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('weather'),
      ],
    ),
    result: GenerateTextResult(
      content: const [
        ToolCallContentPart(
          ToolCallContent(
            toolCallId: 'tool-1',
            toolName: 'weather',
          ),
        ),
      ],
      finishReason: FinishReason.toolCalls,
    ),
  );
}
