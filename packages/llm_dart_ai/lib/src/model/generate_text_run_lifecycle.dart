import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_run_result.dart';
import 'generate_text_run_state.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_step_result.dart';

final class GenerateTextRunLifecycle {
  final GenerateTextOnStepFinish? onStepFinish;
  final GenerateTextOnFinish? onFinish;
  final GenerateTextOnError? onError;
  final String providerId;
  final String modelId;

  var _isCallingOnFinish = false;

  GenerateTextRunLifecycle({
    required this.onStepFinish,
    required this.onFinish,
    required this.onError,
    required this.providerId,
    required this.modelId,
  });

  bool get isCallingOnFinish => _isCallingOnFinish;

  Future<void> finishStep(
    GenerateTextRunState state,
    GenerateTextStepResult step,
  ) async {
    await onStepFinish?.call(step);
    state.addOrReplaceStep(step);
    state.clearActiveStep();
  }

  Future<GenerateTextRunResult> finishSuccessfulRun(
    GenerateTextRunState state,
  ) async {
    final runResult = GenerateTextRunResult(
      steps: state.previousSteps,
    );
    _isCallingOnFinish = true;
    await onFinish?.call(runResult);
    _isCallingOnFinish = false;
    return runResult;
  }

  Future<GenerateTextRunResult> finishAbortedRun(
    GenerateTextRunState state, {
    required String? reason,
  }) async {
    final activeRequest = state.activeRequest;
    final activeStepNumber = state.activeStepNumber;
    if (activeRequest != null && activeStepNumber != null) {
      final abortedStep = GenerateTextStepResult(
        stepNumber: activeStepNumber,
        providerId: providerId,
        modelId: modelId,
        request: activeRequest,
        result: _abortedResult(state.activeResult, reason),
      );
      state.addOrReplaceStep(abortedStep);
      await onStepFinish?.call(abortedStep);
      state.clearActiveStep();
    } else if (state.previousSteps.isNotEmpty) {
      final lastStep = state.previousSteps.last;
      state.previousSteps[state.previousSteps.length - 1] =
          GenerateTextStepResult(
        stepNumber: lastStep.stepNumber,
        providerId: lastStep.providerId,
        modelId: lastStep.modelId,
        request: lastStep.request,
        result: _abortedResult(lastStep.result, reason),
      );
    }

    final runResult = GenerateTextRunResult(
      steps: state.previousSteps,
    );
    await onFinish?.call(runResult);
    return runResult;
  }

  Future<(Object, StackTrace)> notifyError(
    Object error,
    StackTrace stackTrace,
  ) async {
    final callback = onError;
    if (callback == null) {
      return (error, stackTrace);
    }

    try {
      await callback(error, stackTrace);
      return (error, stackTrace);
    } catch (callbackError, callbackStackTrace) {
      return (callbackError, callbackStackTrace);
    }
  }
}

GenerateTextResult _abortedResult(
  GenerateTextResult? result,
  String? reason,
) {
  return GenerateTextResult(
    content: result?.content ?? const [],
    finishReason: FinishReason.aborted,
    rawFinishReason: reason,
    responseId: result?.responseId,
    responseTimestamp: result?.responseTimestamp,
    responseModelId: result?.responseModelId,
    usage: result?.usage,
    providerMetadata: result?.providerMetadata,
    warnings: result?.warnings ?? const [],
  );
}
