import 'dart:async';

import '../common/replay_stream_channel.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' hide ErrorEvent;

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import '../prompt/prompt_validation.dart';
import '../stream/text_stream_event.dart';
import 'generate_text_result_accumulator.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';
import 'language_model_stream_adapter.dart';
import 'stream_result_foundation.dart';
import 'stream_text_cancellation.dart';
import 'stream_text_run_result.dart';

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
    validateProviderPrompt(
      this.prompt,
      context: 'StreamTextRunner.prompt',
    );
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'StreamTextRunner.maxSteps must be at least 1.',
      );
    }
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
    final previousSteps = <GenerateTextStepResult>[];
    var promptHistory = List<PromptMessage>.from(prompt);
    final declaredToolNames = {
      for (final tool in tools) tool.name,
    };
    var streamClosed = false;
    GenerateTextRequest? activeRequest;
    GenerateTextResultAccumulator? activeAccumulator;
    int? activeStepNumber;
    var activeStepOpen = false;

    try {
      await _addEvent(streamResult, const RunStartEvent());
      while (true) {
        final stepNumber = previousSteps.length;
        if (stepNumber >= maxSteps) {
          throw StateError(
            'StreamTextRunner exceeded maxSteps ($maxSteps).',
          );
        }

        validateProviderPrompt(
          promptHistory,
          context: 'StreamTextRunner.prompt',
        );

        final request = GenerateTextRequest(
          prompt: promptHistory,
          tools: tools,
          toolChoice: toolChoice,
          options: options,
          callOptions: callOptions,
        );
        activeRequest = request;
        activeStepNumber = stepNumber;
        activeAccumulator = GenerateTextResultAccumulator();

        final stepStartEvent = GenerateTextStepStartEvent(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          previousSteps: previousSteps,
        );
        await onStepStart?.call(stepStartEvent);
        await _addEvent(
          streamResult,
          StepStartEvent(stepId: _stepId(stepNumber)),
        );
        activeStepOpen = true;
        _throwIfCancelled();

        final accumulator = activeAccumulator;
        final events = adaptLanguageModelStreamEvents(
          cancelOnProviderCancellation(
            model.doStream(request),
            callOptions.cancellation,
          ),
          context: 'StreamTextRunner.modelStream',
        );
        await for (final event in events) {
          accumulator.apply(event);
          await _addEvent(streamResult, event);
        }
        _throwIfCancelled();

        var step = GenerateTextStepResult(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          result: accumulator.build(),
        );
        previousSteps.add(step);

        if (step.finishReason != FinishReason.toolCalls) {
          await onStepFinish?.call(step);
          await _addEvent(
            streamResult,
            StepFinishEvent(stepId: _stepId(stepNumber)),
          );
          stepChannel.add(step);
          activeStepOpen = false;
          activeRequest = null;
          activeStepNumber = null;
          activeAccumulator = null;
          break;
        }

        _throwIfCancelled();
        final toolExecutions =
            await GenerateTextRunnerSupport.executeFunctionTools(
          step,
          declaredToolNames: declaredToolNames,
          functionToolExecutor: functionToolExecutor,
          onToolStart: onToolStart,
          onToolFinish: onToolFinish,
          runnerName: 'StreamTextRunner',
        );
        _throwIfCancelled();
        if (toolExecutions == null) {
          await onStepFinish?.call(step);
          await _addEvent(
            streamResult,
            StepFinishEvent(stepId: _stepId(stepNumber)),
          );
          stepChannel.add(step);
          activeStepOpen = false;
          activeRequest = null;
          activeStepNumber = null;
          activeAccumulator = null;
          break;
        }

        for (final execution in toolExecutions) {
          final event = execution.toTextStreamEvent();
          accumulator.apply(event);
          await _addEvent(streamResult, event);
        }
        step = GenerateTextStepResult(
          stepNumber: step.stepNumber,
          providerId: step.providerId,
          modelId: step.modelId,
          request: step.request,
          result: accumulator.build(),
        );
        previousSteps[previousSteps.length - 1] = step;
        await onStepFinish?.call(step);
        await _addEvent(
          streamResult,
          StepFinishEvent(stepId: _stepId(stepNumber)),
        );
        stepChannel.add(step);
        activeStepOpen = false;
        activeRequest = null;
        activeStepNumber = null;
        activeAccumulator = null;

        if (await isStopConditionMet(
          stopConditions: stopWhen,
          steps: previousSteps,
        )) {
          break;
        }

        promptHistory = [
          ...promptHistory,
          ...GenerateTextRunnerSupport.stepToPromptMessages(
            step,
            runnerName: 'StreamTextRunner',
          ),
        ];
      }

      final runResult = GenerateTextRunResult(
        steps: previousSteps,
      );
      await onFinish?.call(runResult);
      await _addEvent(
        streamResult,
        RunFinishEvent(
          finishReason: runResult.finishReason,
          rawFinishReason: runResult.rawFinishReason,
          usage: runResult.totalUsage,
        ),
      );
      streamResult.completeResult(runResult);
      streamResult.close();
      streamClosed = true;
      stepChannel.close();
    } catch (error, stackTrace) {
      if (isProviderCancellation(error)) {
        await _finishAbortedRun(
          streamResult: streamResult,
          stepChannel: stepChannel,
          previousSteps: previousSteps,
          activeRequest: activeRequest,
          activeAccumulator: activeAccumulator,
          activeStepNumber: activeStepNumber,
          activeStepOpen: activeStepOpen,
          reason: providerCancellationReason(callOptions.cancellation, error),
        );
        return;
      }

      final (reportedError, reportedStackTrace) =
          await _notifyError(error, stackTrace);
      streamResult.completeError(reportedError, reportedStackTrace);
      if (!streamClosed) {
        await _addEvent(
          streamResult,
          ErrorEvent(
            ModelError.fromUnknown(reportedError),
          ),
        );
        await _addEvent(
          streamResult,
          RunFinishEvent(
            finishReason: FinishReason.error,
            rawFinishReason: '$reportedError',
          ),
        );
        streamResult.fail(reportedError, reportedStackTrace);
      }
      stepChannel.addError(reportedError, reportedStackTrace);
    }
  }

  Future<void> _finishAbortedRun({
    required StreamResultController<TextStreamEvent, GenerateTextRunResult>
        streamResult,
    required ReplayStreamChannel<GenerateTextStepResult> stepChannel,
    required List<GenerateTextStepResult> previousSteps,
    required GenerateTextRequest? activeRequest,
    required GenerateTextResultAccumulator? activeAccumulator,
    required int? activeStepNumber,
    required bool activeStepOpen,
    required String? reason,
  }) async {
    if (activeRequest != null &&
        activeAccumulator != null &&
        activeStepNumber != null) {
      activeAccumulator.apply(
        RunFinishEvent(
          finishReason: FinishReason.aborted,
          rawFinishReason: reason,
        ),
      );
      final abortedStep = GenerateTextStepResult(
        stepNumber: activeStepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: activeRequest,
        result: activeAccumulator.build(),
      );
      if (previousSteps.length == activeStepNumber) {
        previousSteps.add(abortedStep);
      } else if (previousSteps.length > activeStepNumber) {
        previousSteps[activeStepNumber] = abortedStep;
      }
      await onStepFinish?.call(abortedStep);
      await _addEvent(streamResult, AbortEvent(reason: reason));
      if (activeStepOpen) {
        await _addEvent(
          streamResult,
          StepFinishEvent(stepId: _stepId(activeStepNumber)),
        );
      }
      stepChannel.add(abortedStep);
    } else {
      await _addEvent(streamResult, AbortEvent(reason: reason));
    }

    final runResult = GenerateTextRunResult(
      steps: previousSteps,
    );
    await onFinish?.call(runResult);
    await _addEvent(
      streamResult,
      RunFinishEvent(
        finishReason: FinishReason.aborted,
        rawFinishReason: reason,
        usage: runResult.totalUsage,
      ),
    );
    streamResult.completeResult(runResult);
    streamResult.close();
    stepChannel.close();
  }

  Future<void> _addEvent(
    StreamResultController<TextStreamEvent, GenerateTextRunResult> streamResult,
    TextStreamEvent event,
  ) async {
    streamResult.addEvent(event);
    await onChunk?.call(event);
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
