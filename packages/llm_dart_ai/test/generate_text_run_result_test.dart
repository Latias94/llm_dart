import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateTextRunResult', () {
    test('requires at least one step', () {
      expect(
        () => GenerateTextRunResult(steps: const []),
        throwsArgumentError,
      );
    });

    test('projects the final step and aggregates usage across steps', () {
      final firstStep = _stepResult(
        stepNumber: 0,
        text: 'First',
        usage: const UsageStats(
          inputTokens: 10,
          outputTokens: 5,
          totalTokens: 15,
          reasoningTokens: 2,
        ),
        finishReason: FinishReason.toolCalls,
      );
      final secondStep = _stepResult(
        stepNumber: 1,
        text: 'Second',
        usage: const UsageStats(
          inputTokens: 3,
          outputTokens: 7,
          totalTokens: 10,
          reasoningTokens: 1,
        ),
        finishReason: FinishReason.stop,
      );

      final run = GenerateTextRunResult(
        steps: [
          firstStep,
          secondStep,
        ],
      );

      expect(run.lastStep, same(secondStep));
      expect(run.text, 'Second');
      expect(run.finishReason, FinishReason.stop);
      expect(
          run.totalUsage,
          const UsageStats(
            inputTokens: 13,
            outputTokens: 12,
            totalTokens: 25,
            reasoningTokens: 3,
          ));
    });
  });

  group('GenerateTextStepStartEvent', () {
    test('captures immutable previous step snapshots', () {
      final request = GenerateTextRequest(
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
      );
      final previousStep = _stepResult(
        stepNumber: 0,
        text: 'First',
      );

      final event = GenerateTextStepStartEvent(
        stepNumber: 1,
        providerId: 'openai',
        modelId: 'gpt-test',
        request: request,
        previousSteps: [previousStep],
      );

      expect(event.stepNumber, 1);
      expect(event.providerId, 'openai');
      expect(event.modelId, 'gpt-test');
      expect(event.request, same(request));
      expect(event.previousSteps, [previousStep]);
      expect(
        () => event.previousSteps.add(previousStep),
        throwsUnsupportedError,
      );
    });
  });
}

GenerateTextStepResult _stepResult({
  required int stepNumber,
  required String text,
  UsageStats? usage,
  FinishReason finishReason = FinishReason.stop,
}) {
  return GenerateTextStepResult(
    stepNumber: stepNumber,
    providerId: 'openai',
    modelId: 'gpt-test',
    request: GenerateTextRequest(
      prompt: [
        UserPromptMessage.text('Prompt $stepNumber'),
      ],
    ),
    result: GenerateTextResult(
      content: [
        TextContentPart(text),
      ],
      finishReason: finishReason,
      usage: usage,
    ),
  );
}
