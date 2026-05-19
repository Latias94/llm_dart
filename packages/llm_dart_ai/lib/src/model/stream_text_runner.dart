import 'dart:async';

import '../common/replay_stream_channel.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' hide ErrorEvent;

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_result_accumulator.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_step_continuation_resolver.dart';
import 'generate_text_step_planner.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';
import 'language_model_stream_adapter.dart';
import 'stream_result_foundation.dart';
import 'stream_text_event_emitter.dart';
import 'stream_text_cancellation.dart';
import 'stream_text_run_lifecycle.dart';
import 'stream_text_run_result.dart';
import 'stream_text_run_state.dart';

export 'stream_text_run_result.dart' show StreamTextRunResult;

final class StreamTextRunner {
  final LanguageModel model;
  final List<PromptMessage> prompt;
  final List<FunctionToolDefinition> tools;
  final ToolChoice? toolChoice;
  final GenerateTextOptions options;
  final CallOptions callOptions;
  final GenerateTextFunctionToolExecutor? functionToolExecutor;
  final int maxSteps;
  final List<GenerateTextStopCondition> stopWhen;
  final GenerateTextOnStepStart? onStepStart;
  final GenerateTextOnStepFinish? onStepFinish;
  final GenerateTextOnToolStart? onToolStart;
  final GenerateTextOnToolFinish? onToolFinish;
  final GenerateTextOnFinish? onFinish;
  final StreamTextOnChunk? onChunk;
  final GenerateTextOnError? onError;

  StreamTextRunner({
    required this.model,
    List<PromptMessage>? prompt,
    List<ModelMessage>? messages,
    List<FunctionToolDefinition> tools = const [],
    this.toolChoice,
    this.options = const GenerateTextOptions(),
    this.callOptions = const CallOptions(),
    this.functionToolExecutor,
    this.maxSteps = 8,
    Iterable<GenerateTextStopCondition> stopWhen = const [],
    this.onStepStart,
    this.onStepFinish,
    this.onToolStart,
    this.onToolFinish,
    this.onFinish,
    this.onChunk,
    this.onError,
  })  : stopWhen = List.unmodifiable(stopWhen),
        prompt = resolveProviderPrompt(
          prompt: prompt,
          messages: messages,
        ),
        tools = List.unmodifiable(tools) {
    GenerateTextStepPlanner.validatePromptForRunner(
      runnerName: 'StreamTextRunner',
      prompt: this.prompt,
    );
    GenerateTextStepPlanner.validateMaxSteps(
      runnerName: 'StreamTextRunner',
      maxSteps: maxSteps,
    );
  }

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
    var promptHistory = List<PromptMessage>.from(prompt);
    final planner = GenerateTextStepPlanner(
      runnerName: 'StreamTextRunner',
      model: model,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
      maxSteps: maxSteps,
    );
    final declaredToolNames = planner.declaredToolNames;
    final continuationResolver = GenerateTextStepContinuationResolver(
      declaredToolNames: declaredToolNames,
      functionToolExecutor: functionToolExecutor,
      onToolStart: onToolStart,
      onToolFinish: onToolFinish,
      stopConditions: stopWhen,
      runnerName: 'StreamTextRunner',
    );
    var streamClosed = false;
    final emitter = StreamTextEventEmitter(
      streamResult: streamResult,
      onChunk: onChunk,
    );
    final lifecycle = StreamTextRunLifecycle(
      emitter: emitter,
      stepChannel: stepChannel,
      onStepFinish: onStepFinish,
      onFinish: onFinish,
      stepId: _stepId,
      providerId: model.providerId,
      modelId: model.modelId,
    );

    try {
      await emitter.add(const RunStartEvent());
      while (true) {
        final plan = planner.planNextStep(
          promptHistory: promptHistory,
          previousSteps: state.previousSteps,
        );
        final accumulator = GenerateTextResultAccumulator();
        state.beginStep(
          stepNumber: plan.stepNumber,
          request: plan.request,
          accumulator: accumulator,
        );

        await onStepStart?.call(plan.startEvent);
        await emitter.add(
          StepStartEvent(stepId: _stepId(plan.stepNumber)),
        );
        state.markActiveStepOpen();
        _throwIfCancelled();

        final events = adaptLanguageModelStreamEvents(
          cancelOnProviderCancellation(
            model.doStream(plan.request),
            callOptions.cancellation,
          ),
          context: 'StreamTextRunner.modelStream',
        );
        await for (final event in events) {
          accumulator.apply(event);
          await emitter.add(event);
        }
        _throwIfCancelled();

        var step = GenerateTextStepResult(
          stepNumber: plan.stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: plan.request,
          result: accumulator.build(),
        );
        state.addOrReplaceStep(step);

        final continuation = await continuationResolver.resolve(
          step: step,
          promptHistory: promptHistory,
          finishStep: (step) async {
            await lifecycle.finishStep(state, step);
            return state.previousSteps;
          },
          applyToolExecutions: (step, executions) async {
            for (final execution in executions) {
              final event = execution.toTextStreamEvent();
              accumulator.apply(event);
              await emitter.add(event);
            }
            return GenerateTextStepResult(
              stepNumber: step.stepNumber,
              providerId: step.providerId,
              modelId: step.modelId,
              request: step.request,
              result: accumulator.build(),
            );
          },
          throwIfCancelled: _throwIfCancelled,
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
          reason: providerCancellationReason(callOptions.cancellation, error),
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

  void _throwIfCancelled() {
    callOptions.cancellation?.throwIfCancelled();
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
  return StreamTextRunner(
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
    onChunk: onChunk,
    onError: onError,
  ).run();
}
