import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_runner_prompt_replay.dart' as prompt_replay;
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';

final class GenerateTextLoopContinuation {
  final bool shouldContinue;
  final List<PromptMessage> promptHistory;

  GenerateTextLoopContinuation.stop({
    required List<PromptMessage> promptHistory,
  })  : shouldContinue = false,
        promptHistory = List.unmodifiable(promptHistory);

  GenerateTextLoopContinuation.continueWithPrompt({
    required List<PromptMessage> promptHistory,
  })  : shouldContinue = true,
        promptHistory = List.unmodifiable(promptHistory);
}

Future<GenerateTextLoopContinuation> resolveGenerateTextLoopContinuation({
  required List<PromptMessage> promptHistory,
  required GenerateTextStepResult step,
  required List<GenerateTextStepResult> completedSteps,
  required List<GenerateTextStopCondition> stopConditions,
  required String runnerName,
}) async {
  if (await isStopConditionMet(
    stopConditions: stopConditions,
    steps: completedSteps,
  )) {
    return GenerateTextLoopContinuation.stop(promptHistory: promptHistory);
  }

  return GenerateTextLoopContinuation.continueWithPrompt(
    promptHistory: [
      ...promptHistory,
      ...prompt_replay.stepToPromptMessages(
        step,
        runnerName: runnerName,
      ),
    ],
  );
}
