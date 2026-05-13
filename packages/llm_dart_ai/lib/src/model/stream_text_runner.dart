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
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';
import 'language_model_stream_adapter.dart';

final class StreamTextRunResult extends StreamView<TextStreamEvent> {
  final Future<GenerateTextRunResult> result;
  final Stream<GenerateTextStepResult> stepStream;

  StreamTextRunResult._({
    required Stream<TextStreamEvent> stream,
    required this.result,
    required this.stepStream,
  }) : super(stream);

  Stream<TextStreamEvent> get eventStream => this;

  Stream<TextStreamEvent> get textStream => eventStream;

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
    this.onStepStart,
    this.onStepFinish,
    this.onToolStart,
    this.onToolFinish,
    this.onFinish,
    this.onChunk,
    this.onError,
  })  : prompt = resolveProviderPrompt(
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
    final eventChannel = ReplayStreamChannel<TextStreamEvent>();
    final stepChannel = ReplayStreamChannel<GenerateTextStepResult>();
    final resultCompleter = Completer<GenerateTextRunResult>();

    unawaited(
      _runLoop(
        eventChannel: eventChannel,
        stepChannel: stepChannel,
        resultCompleter: resultCompleter,
      ),
    );

    return StreamTextRunResult._(
      stream: eventChannel.stream,
      result: resultCompleter.future,
      stepStream: stepChannel.stream,
    );
  }

  Future<void> _runLoop({
    required ReplayStreamChannel<TextStreamEvent> eventChannel,
    required ReplayStreamChannel<GenerateTextStepResult> stepChannel,
    required Completer<GenerateTextRunResult> resultCompleter,
  }) async {
    final previousSteps = <GenerateTextStepResult>[];
    var promptHistory = List<PromptMessage>.from(prompt);
    final declaredToolNames = {
      for (final tool in tools) tool.name,
    };
    var streamClosed = false;

    try {
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

        final stepStartEvent = GenerateTextStepStartEvent(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          previousSteps: previousSteps,
        );
        await onStepStart?.call(stepStartEvent);
        await _addEvent(
          eventChannel,
          StepStartEvent(stepId: _stepId(stepNumber)),
        );

        final accumulator = GenerateTextResultAccumulator();
        final events = adaptLanguageModelStreamEvents(
          model.doStream(request),
          context: 'StreamTextRunner.modelStream',
        );
        await for (final event in events) {
          accumulator.apply(event);
          await _addEvent(eventChannel, event);
        }

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
            eventChannel,
            StepFinishEvent(stepId: _stepId(stepNumber)),
          );
          stepChannel.add(step);
          break;
        }

        final toolExecutions =
            await GenerateTextRunnerSupport.executeFunctionTools(
          step,
          declaredToolNames: declaredToolNames,
          functionToolExecutor: functionToolExecutor,
          onToolStart: onToolStart,
          onToolFinish: onToolFinish,
          runnerName: 'StreamTextRunner',
        );
        if (toolExecutions == null) {
          await onStepFinish?.call(step);
          await _addEvent(
            eventChannel,
            StepFinishEvent(stepId: _stepId(stepNumber)),
          );
          stepChannel.add(step);
          break;
        }

        for (final execution in toolExecutions) {
          final event = execution.toTextStreamEvent();
          accumulator.apply(event);
          await _addEvent(eventChannel, event);
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
          eventChannel,
          StepFinishEvent(stepId: _stepId(stepNumber)),
        );
        stepChannel.add(step);

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
      if (!resultCompleter.isCompleted) {
        resultCompleter.complete(runResult);
      }
      eventChannel.close();
      streamClosed = true;
      stepChannel.close();
    } catch (error, stackTrace) {
      final (reportedError, reportedStackTrace) =
          await _notifyError(error, stackTrace);
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(reportedError, reportedStackTrace);
      }
      if (!streamClosed) {
        await _addEvent(
          eventChannel,
          ErrorEvent(
            ModelError.fromUnknown(reportedError),
          ),
        );
        eventChannel.addError(reportedError, reportedStackTrace);
      }
      stepChannel.addError(reportedError, reportedStackTrace);
    }
  }

  Future<void> _addEvent(
    ReplayStreamChannel<TextStreamEvent> eventChannel,
    TextStreamEvent event,
  ) async {
    eventChannel.add(event);
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
    onStepStart: onStepStart,
    onStepFinish: onStepFinish,
    onToolStart: onToolStart,
    onToolFinish: onToolFinish,
    onFinish: onFinish,
    onChunk: onChunk,
    onError: onError,
  ).run();
}
