import 'dart:async';

import '../common/replay_stream_channel.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_result_accumulator.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';

final class StreamTextRunResult extends StreamView<TextStreamEvent> {
  final Future<GenerateTextRunResult> result;
  final Stream<GenerateTextStepResult> stepStream;

  StreamTextRunResult._({
    required Stream<TextStreamEvent> stream,
    required this.result,
    required this.stepStream,
  }) : super(stream);

  Stream<TextStreamEvent> get eventStream => this;

  Future<List<GenerateTextStepResult>> get steps => result.then(
        (value) => value.steps,
      );

  Future<GenerateTextStepResult> get lastStep => result.then(
        (value) => value.lastStep,
      );

  Future<UsageStats?> get totalUsage => result.then(
        (value) => value.totalUsage,
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
  final GenerateTextOnFinish? onFinish;
  final StreamTextOnChunk? onChunk;
  final GenerateTextOnError? onError;

  StreamTextRunner({
    required this.model,
    required List<PromptMessage> prompt,
    List<FunctionToolDefinition> tools = const [],
    this.toolChoice,
    this.options = const GenerateTextOptions(),
    this.callOptions = const CallOptions(),
    this.functionToolExecutor,
    this.maxSteps = 8,
    this.onStepStart,
    this.onStepFinish,
    this.onFinish,
    this.onChunk,
    this.onError,
  })  : prompt = List.unmodifiable(prompt),
        tools = List.unmodifiable(tools) {
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

    try {
      while (true) {
        final stepNumber = previousSteps.length;
        if (stepNumber >= maxSteps) {
          throw StateError(
            'StreamTextRunner exceeded maxSteps ($maxSteps).',
          );
        }

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

        final accumulator = GenerateTextResultAccumulator();
        await for (final event in model.doStream(request)) {
          accumulator.apply(event);
          eventChannel.add(event);
          await onChunk?.call(event);
        }

        final step = GenerateTextStepResult(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          result: accumulator.build(),
        );
        await onStepFinish?.call(step);
        previousSteps.add(step);
        stepChannel.add(step);

        if (step.finishReason != FinishReason.toolCalls) {
          break;
        }

        final toolContinuation =
            await GenerateTextRunnerSupport.buildFunctionToolContinuation(
          step,
          declaredToolNames: declaredToolNames,
          functionToolExecutor: functionToolExecutor,
          runnerName: 'StreamTextRunner',
        );
        if (toolContinuation == null) {
          break;
        }

        promptHistory = [
          ...promptHistory,
          ...GenerateTextRunnerSupport.stepToPromptMessages(
            step,
            runnerName: 'StreamTextRunner',
          ),
          ...toolContinuation,
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
      stepChannel.close();
    } catch (error, stackTrace) {
      final (reportedError, reportedStackTrace) =
          await _notifyError(error, stackTrace);
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(reportedError, reportedStackTrace);
      }
      eventChannel.addError(reportedError, reportedStackTrace);
      stepChannel.addError(reportedError, reportedStackTrace);
    }
  }

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
  required List<PromptMessage> prompt,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  GenerateTextOnStepStart? onStepStart,
  GenerateTextOnStepFinish? onStepFinish,
  GenerateTextOnFinish? onFinish,
  StreamTextOnChunk? onChunk,
  GenerateTextOnError? onError,
}) {
  return StreamTextRunner(
    model: model,
    prompt: prompt,
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    onStepStart: onStepStart,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
    onChunk: onChunk,
    onError: onError,
  ).run();
}
