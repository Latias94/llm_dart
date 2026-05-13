import 'dart:async';

import '../common/replay_stream_channel.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart' hide ErrorEvent;

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import '../prompt/prompt_validation.dart';
import '../stream/text_stream_event.dart';
import '../ui/chat_ui_message.dart';
import '../ui/chat_ui_stream_chunk.dart';
import '../ui/chat_ui_stream_projection.dart';
import 'generate_text_result_accumulator.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';
import 'language_model_stream_adapter.dart';
import 'stream_result_foundation.dart';

final class StreamTextRunResult extends StreamView<TextStreamEvent> {
  final StreamResultHandle<TextStreamEvent, GenerateTextRunResult> _foundation;
  final Stream<GenerateTextStepResult> stepStream;

  StreamTextRunResult._({
    required StreamResultHandle<TextStreamEvent, GenerateTextRunResult>
        foundation,
    required this.stepStream,
  })  : _foundation = foundation,
        super(foundation.eventStream);

  Stream<TextStreamEvent> get eventStream => this;

  Stream<TextStreamEvent> get textStream => eventStream;

  Future<GenerateTextRunResult> get result => _foundation.result;

  Stream<ChatUiStreamChunk> chatUiStream({
    String? messageId,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
  }) {
    return projectTextStreamEventStream(
      eventStream,
      messageId: messageId,
      messageMetadata: messageMetadata,
      leadingDataParts: leadingDataParts,
      finalMessageMetadata: finalMessageMetadata,
    );
  }

  Future<List<GenerateTextStepResult>> get steps => result.then(
        (value) => value.steps,
      );

  Future<GenerateTextStepResult> get lastStep => result.then(
        (value) => value.lastStep,
      );

  Future<UsageStats?> get totalUsage => result.then(
        (value) => value.totalUsage,
      );

  Future<UsageStats?> get usage => totalUsage;

  Future<List<ContentPart>> get content => result.then(
        (value) => value.content,
      );

  Future<String> get text => result.then(
        (value) => value.text,
      );

  Future<String?> get reasoningText => result.then(
        (value) => value.reasoningText,
      );

  Future<FinishReason> get finishReason => result.then(
        (value) => value.finishReason,
      );

  Future<String?> get rawFinishReason => result.then(
        (value) => value.rawFinishReason,
      );

  Future<List<SourceReference>> get sources => result.then(
        (value) => value.sources,
      );

  Future<List<GeneratedFile>> get files => result.then(
        (value) => value.files,
      );

  Future<List<ToolCallContent>> get toolCalls => result.then(
        (value) => value.toolCalls,
      );

  Future<List<ToolResultContent>> get toolResults => result.then(
        (value) => value.toolResults,
      );

  Future<List<ToolApprovalRequestContent>> get toolApprovalRequests =>
      result.then(
        (value) => value.toolApprovalRequests,
      );

  Future<String?> get responseId => result.then(
        (value) => value.responseId,
      );

  Future<DateTime?> get responseTimestamp => result.then(
        (value) => value.responseTimestamp,
      );

  Future<String?> get responseModelId => result.then(
        (value) => value.responseModelId,
      );

  Future<ProviderMetadata?> get providerMetadata => result.then(
        (value) => value.providerMetadata,
      );
}

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

    return StreamTextRunResult._(
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
          _cancelOnProviderCancellation(
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
      if (_isCancelled(error)) {
        await _finishAbortedRun(
          streamResult: streamResult,
          stepChannel: stepChannel,
          previousSteps: previousSteps,
          activeRequest: activeRequest,
          activeAccumulator: activeAccumulator,
          activeStepNumber: activeStepNumber,
          activeStepOpen: activeStepOpen,
          reason: _cancelReason(error),
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

  bool _isCancelled(Object error) {
    return ProviderCancellation.isCancel(error);
  }

  String? _cancelReason(Object error) {
    if (error is ProviderCancelledException) {
      return error.reason?.toString();
    }

    return callOptions.cancellation?.reason?.toString();
  }
}

Stream<T> _cancelOnProviderCancellation<T>(
  Stream<T> source,
  ProviderCancellation? cancellation,
) {
  if (cancellation == null) {
    return source;
  }

  StreamSubscription<T>? subscription;
  late StreamController<T> controller;
  var completed = false;

  void failWithCancellation(Object? reason) {
    if (completed) {
      return;
    }
    completed = true;

    final error = ProviderCancelledException(reason);
    final stackTrace = StackTrace.current;

    Future<void> emitError() async {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
        await controller.close();
      }
    }

    final cancelFuture = subscription?.cancel();
    if (cancelFuture == null) {
      unawaited(emitError());
    } else {
      unawaited(cancelFuture.whenComplete(emitError));
    }
  }

  controller = StreamController<T>(
    onListen: () {
      if (cancellation.isCancelled) {
        failWithCancellation(cancellation.reason);
        return;
      }

      subscription = source.listen(
        (event) {
          if (cancellation.isCancelled) {
            failWithCancellation(cancellation.reason);
            return;
          }

          if (!completed) {
            controller.add(event);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (completed) {
            return;
          }
          completed = true;
          controller.addError(error, stackTrace);
          unawaited(controller.close());
        },
        onDone: () {
          if (completed) {
            return;
          }
          completed = true;
          unawaited(controller.close());
        },
      );

      unawaited(
        cancellation.whenCancelled.then(failWithCancellation),
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      completed = true;
      await subscription?.cancel();
    },
  );

  return controller.stream;
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
