import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_step_result.dart';

final class GenerateTextRunState {
  final List<GenerateTextStepResult> previousSteps = <GenerateTextStepResult>[];

  GenerateTextRequest? activeRequest;
  int? activeStepNumber;
  GenerateTextResult? activeResult;

  int get nextStepNumber => previousSteps.length;

  void beginStep({
    required int stepNumber,
    required GenerateTextRequest request,
  }) {
    activeRequest = request;
    activeStepNumber = stepNumber;
    activeResult = null;
  }

  void setActiveResult(GenerateTextResult result) {
    activeResult = result;
  }

  void clearActiveStep() {
    activeRequest = null;
    activeStepNumber = null;
    activeResult = null;
  }

  void addOrReplaceStep(GenerateTextStepResult step) {
    if (previousSteps.length == step.stepNumber) {
      previousSteps.add(step);
      return;
    }

    if (previousSteps.length > step.stepNumber) {
      previousSteps[step.stepNumber] = step;
      return;
    }

    throw StateError(
      'Cannot store generate text step ${step.stepNumber} after '
      '${previousSteps.length} completed steps.',
    );
  }
}
