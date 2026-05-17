import 'package:llm_dart_provider/llm_dart_provider.dart' hide ErrorEvent;

import '../common/replay_stream_channel.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_step_result.dart';
import 'stream_text_event_emitter.dart';
import 'stream_text_run_state.dart';

typedef StreamTextStepId = String Function(int stepNumber);

final class StreamTextRunLifecycle {
  final StreamTextEventEmitter emitter;
  final ReplayStreamChannel<GenerateTextStepResult> stepChannel;
  final GenerateTextOnStepFinish? onStepFinish;
  final GenerateTextOnFinish? onFinish;
  final StreamTextStepId stepId;
  final String providerId;
  final String modelId;

  StreamTextRunLifecycle({
    required this.emitter,
    required this.stepChannel,
    required this.onStepFinish,
    required this.onFinish,
    required this.stepId,
    required this.providerId,
    required this.modelId,
  });

  Future<void> finishStep(
    StreamTextRunState state,
    GenerateTextStepResult step,
  ) async {
    state.addOrReplaceStep(step);
    await onStepFinish?.call(step);
    await emitter.add(
      StepFinishEvent(stepId: stepId(step.stepNumber)),
    );
    stepChannel.add(step);
    state.clearActiveStep();
  }

  Future<void> finishSuccessfulRun(
    StreamTextRunState state,
  ) async {
    final runResult = GenerateTextRunResult(
      steps: state.previousSteps,
    );
    await onFinish?.call(runResult);
    await emitter.add(
      RunFinishEvent(
        finishReason: runResult.finishReason,
        rawFinishReason: runResult.rawFinishReason,
        usage: runResult.totalUsage,
      ),
    );
    emitter.streamResult.completeResult(runResult);
    close();
  }

  Future<void> finishAbortedRun(
    StreamTextRunState state, {
    required String? reason,
  }) async {
    final activeStep = _abortedActiveStep(state, reason: reason);
    if (activeStep != null) {
      await onStepFinish?.call(activeStep);
      await emitter.add(AbortEvent(reason: reason));
      if (state.activeStepOpen) {
        await emitter.add(
          StepFinishEvent(stepId: stepId(activeStep.stepNumber)),
        );
      }
      stepChannel.add(activeStep);
      state.clearActiveStep();
    } else {
      await emitter.add(AbortEvent(reason: reason));
    }

    final runResult = GenerateTextRunResult(
      steps: state.previousSteps,
    );
    await onFinish?.call(runResult);
    await emitter.add(
      RunFinishEvent(
        finishReason: FinishReason.aborted,
        rawFinishReason: reason,
        usage: runResult.totalUsage,
      ),
    );
    emitter.streamResult.completeResult(runResult);
    close();
  }

  Future<void> failRun(
    Object error,
    StackTrace stackTrace, {
    required bool streamClosed,
  }) async {
    emitter.streamResult.completeError(error, stackTrace);
    if (!streamClosed) {
      await emitter.add(
        ErrorEvent(
          ModelError.fromUnknown(error),
        ),
      );
      await emitter.add(
        RunFinishEvent(
          finishReason: FinishReason.error,
          rawFinishReason: '$error',
        ),
      );
      emitter.streamResult.fail(error, stackTrace);
    }
    stepChannel.addError(error, stackTrace);
  }

  void close() {
    emitter.streamResult.close();
    stepChannel.close();
  }

  GenerateTextStepResult? _abortedActiveStep(
    StreamTextRunState state, {
    required String? reason,
  }) {
    final activeRequest = state.activeRequest;
    final activeAccumulator = state.activeAccumulator;
    final activeStepNumber = state.activeStepNumber;
    if (activeRequest == null ||
        activeAccumulator == null ||
        activeStepNumber == null) {
      return null;
    }

    activeAccumulator.apply(
      RunFinishEvent(
        finishReason: FinishReason.aborted,
        rawFinishReason: reason,
      ),
    );
    final abortedStep = GenerateTextStepResult(
      stepNumber: activeStepNumber,
      providerId: providerId,
      modelId: modelId,
      request: activeRequest,
      result: activeAccumulator.build(),
    );
    state.addOrReplaceStep(abortedStep);
    return abortedStep;
  }
}
