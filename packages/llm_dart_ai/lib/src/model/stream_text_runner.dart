import 'dart:async';

import '../common/replay_stream_channel.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' hide ErrorEvent;

import '../prompt/model_message.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';
import 'stream_result_foundation.dart';
import 'stream_text_event_emitter.dart';
import 'stream_text_cancellation.dart';
import 'stream_text_run_lifecycle.dart';
import 'stream_text_run_result.dart';
import 'stream_text_run_state.dart';
import 'stream_text_step_executor.dart';
import 'text_generation_request.dart';
import 'text_generation_runtime_request.dart';

export 'stream_text_run_result.dart' show StreamTextRunResult;

final class StreamTextRunner {
  static const _runnerName = 'StreamTextRunner';

  final TextGenerationRuntimeRequest _runtime;
  final StreamTextOnChunk? onChunk;

  StreamTextRunner._({
    required TextGenerationRuntimeRequest runtime,
    this.onChunk,
  }) : _runtime = runtime {
    _runtime.validateForRunner(
      runnerName: _runnerName,
      validateInitialPrompt: true,
    );
  }

  StreamTextRunner.fromRequest({
    required TextGenerationRequest request,
    StreamTextOnChunk? onChunk,
  }) : this._(
          runtime: TextGenerationRuntimeRequest.fromRequest(request),
          onChunk: onChunk,
        );

  StreamTextRunner({
    required LanguageModel model,
    List<PromptMessage>? prompt,
    List<ModelMessage>? messages,
    List<FunctionToolDefinition> tools = const [],
    ToolChoice? toolChoice,
    GenerateTextOptions options = const GenerateTextOptions(),
    CallOptions callOptions = const CallOptions(),
    GenerateTextFunctionToolExecutor? functionToolExecutor,
    int maxSteps = 8,
    Iterable<GenerateTextStopCondition> stopWhen = const [],
    GenerateTextOnStepStart? onStepStart,
    GenerateTextOnStepFinish? onStepFinish,
    GenerateTextOnToolStart? onToolStart,
    GenerateTextOnToolFinish? onToolFinish,
    GenerateTextOnFinish? onFinish,
    StreamTextOnChunk? onChunk,
    GenerateTextOnError? onError,
  }) : this.fromRequest(
          request: TextGenerationRequest.resolve(
            model: model,
            prompt: prompt,
            messages: messages,
            tools: tools,
            toolChoice: toolChoice,
            options: options,
            callOptions: callOptions,
            functionToolExecutor: functionToolExecutor,
            maxSteps: maxSteps,
            stopWhen: stopWhen,
            onStepStart: onStepStart,
            onStepFinish: onStepFinish,
            onToolStart: onToolStart,
            onToolFinish: onToolFinish,
            onFinish: onFinish,
            onError: onError,
          ),
          onChunk: onChunk,
        );

  StreamTextRunResult run() {
    final streamResult =
        StreamResultController<TextStreamEvent, GenerateTextRunResult>();
    final stepChannel = ReplayStreamChannel<GenerateTextStepResult>();

    unawaited(
      _runLoop(
        streamResult: streamResult,
        stepChannel: stepChannel,
      ),
    );

    return createStreamTextRunResult(
      foundation: streamResult.handle,
      stepStream: stepChannel.stream,
    );
  }

  Future<void> _runLoop({
    required StreamResultController<TextStreamEvent, GenerateTextRunResult>
        streamResult,
    required ReplayStreamChannel<GenerateTextStepResult> stepChannel,
  }) async {
    final state = StreamTextRunState();
    var promptHistory = _runtime.createPromptHistory();
    final stepContext = _runtime.createStepContext(runnerName: _runnerName);
    var streamClosed = false;
    final emitter = StreamTextEventEmitter(
      streamResult: streamResult,
      onChunk: onChunk,
    );
    final stepExecutor = StreamTextStepExecutor(
      model: _runtime.model,
      callOptions: _runtime.callOptions,
      emitter: emitter,
      stepId: _stepId,
    );
    final lifecycle = StreamTextRunLifecycle(
      emitter: emitter,
      stepChannel: stepChannel,
      onStepFinish: _runtime.onStepFinish,
      onFinish: _runtime.onFinish,
      stepId: _stepId,
      providerId: _runtime.model.providerId,
      modelId: _runtime.model.modelId,
    );

    try {
      await emitter.add(const RunStartEvent());
      while (true) {
        final plan = stepContext.planner.planNextStep(
          promptHistory: promptHistory,
          previousSteps: state.previousSteps,
        );
        final execution = await stepExecutor.executeStep(
          plan,
          beginStep: (accumulator) {
            state.beginStep(
              stepNumber: plan.stepNumber,
              request: plan.request,
              accumulator: accumulator,
            );
          },
          onStepStart: () async => _runtime.onStepStart?.call(plan.startEvent),
          markStepOpen: state.markActiveStepOpen,
          throwIfCancelled: _runtime.throwIfCancelled,
        );
        var step = execution.step;
        state.addOrReplaceStep(step);

        final continuation = await stepContext.continuationResolver.resolve(
          step: step,
          promptHistory: promptHistory,
          finishStep: (step) async {
            await lifecycle.finishStep(state, step);
            return state.previousSteps;
          },
          applyToolExecutions: (step, executions) async {
            return stepExecutor.applyToolExecutions(
              step,
              executions,
              execution.accumulator,
            );
          },
          throwIfCancelled: _runtime.throwIfCancelled,
        );
        if (!continuation.shouldContinue) {
          break;
        }
        promptHistory = continuation.promptHistory;
      }

      await lifecycle.finishSuccessfulRun(state);
      streamClosed = true;
    } catch (error, stackTrace) {
      if (isProviderCancellation(error)) {
        await lifecycle.finishAbortedRun(
          state,
          reason: providerCancellationReason(
            _runtime.callOptions.cancellation,
            error,
          ),
        );
        return;
      }

      final (reportedError, reportedStackTrace) =
          await _notifyError(error, stackTrace);
      await lifecycle.failRun(
        reportedError,
        reportedStackTrace,
        streamClosed: streamClosed,
      );
    }
  }

  String _stepId(int stepNumber) => 'step-$stepNumber';

  Future<(Object, StackTrace)> _notifyError(
    Object error,
    StackTrace stackTrace,
  ) async {
    final callback = _runtime.onError;
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

StreamTextRunResult streamTextRun({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
  GenerateTextOnStepStart? onStepStart,
  GenerateTextOnStepFinish? onStepFinish,
  GenerateTextOnToolStart? onToolStart,
  GenerateTextOnToolFinish? onToolFinish,
  GenerateTextOnFinish? onFinish,
  StreamTextOnChunk? onChunk,
  GenerateTextOnError? onError,
}) {
  return streamTextRunRequest(
    TextGenerationRequest.resolve(
      model: model,
      prompt: prompt,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
      functionToolExecutor: functionToolExecutor,
      maxSteps: maxSteps,
      stopWhen: stopWhen,
      onStepStart: onStepStart,
      onStepFinish: onStepFinish,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      onFinish: onFinish,
      onError: onError,
    ),
    onChunk: onChunk,
  );
}

StreamTextRunResult streamTextRunRequest(
  TextGenerationRequest request, {
  StreamTextOnChunk? onChunk,
}) {
  return StreamTextRunner.fromRequest(
    request: request,
    onChunk: onChunk,
  ).run();
}
