import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_result_accumulator.dart';
import 'generate_text_step_result.dart';

final class StreamTextRunState {
  final List<GenerateTextStepResult> previousSteps = <GenerateTextStepResult>[];

  GenerateTextRequest? activeRequest;
  GenerateTextResultAccumulator? activeAccumulator;
  int? activeStepNumber;
  bool activeStepOpen = false;

  int get nextStepNumber => previousSteps.length;

  void beginStep({
    required int stepNumber,
    required GenerateTextRequest request,
    required GenerateTextResultAccumulator accumulator,
  }) {
    activeRequest = request;
    activeStepNumber = stepNumber;
    activeAccumulator = accumulator;
  }

  void markActiveStepOpen() {
    activeStepOpen = true;
  }

  void clearActiveStep() {
    activeRequest = null;
    activeStepNumber = null;
    activeAccumulator = null;
    activeStepOpen = false;
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
      'Cannot store stream text step ${step.stepNumber} after '
      '${previousSteps.length} completed steps.',
    );
  }
}
