import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import '../prompt/prompt_validation.dart';
import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';

final class GenerateTextRunner {
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
  final GenerateTextOnError? onError;

  GenerateTextRunner({
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
    this.onError,
  })  : stopWhen = List.unmodifiable(stopWhen),
        prompt = resolveProviderPrompt(
          prompt: prompt,
          messages: messages,
        ),
        tools = List.unmodifiable(tools) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        'GenerateTextRunner.maxSteps must be at least 1.',
      );
    }
  }

  Future<GenerateTextRunResult> run() async {
    final previousSteps = <GenerateTextStepResult>[];
    GenerateTextRequest? activeRequest;
    int? activeStepNumber;
    GenerateTextResult? activeResult;
    var isCallingOnFinish = false;

    try {
      var promptHistory = List<PromptMessage>.from(prompt);
      final declaredToolNames = {
        for (final tool in tools) tool.name,
      };

      while (true) {
        final stepNumber = previousSteps.length;
        if (stepNumber >= maxSteps) {
          throw StateError(
            'GenerateTextRunner exceeded maxSteps ($maxSteps).',
          );
        }

        validateProviderPrompt(
          promptHistory,
          context: 'GenerateTextRunner.prompt',
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
        activeResult = null;

        final stepStartEvent = GenerateTextStepStartEvent(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          previousSteps: previousSteps,
        );
        await onStepStart?.call(stepStartEvent);
        _throwIfCancelled();

        final result = await model.doGenerate(request);
        activeResult = result;
        _throwIfCancelled();
        var step = GenerateTextStepResult(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          result: result,
        );

        if (step.finishReason != FinishReason.toolCalls) {
          await onStepFinish?.call(step);
          previousSteps.add(step);
          activeRequest = null;
          activeStepNumber = null;
          activeResult = null;
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
          runnerName: 'GenerateTextRunner',
        );
        _throwIfCancelled();
        if (toolExecutions == null) {
          await onStepFinish?.call(step);
          previousSteps.add(step);
          activeRequest = null;
          activeStepNumber = null;
          activeResult = null;
          break;
        }

        step = GenerateTextRunnerSupport.addToolExecutionsToStep(
          step,
          toolExecutions,
        );
        await onStepFinish?.call(step);
        previousSteps.add(step);
        activeRequest = null;
        activeStepNumber = null;
        activeResult = null;

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
            runnerName: 'GenerateTextRunner',
          ),
        ];
      }

      final runResult = GenerateTextRunResult(
        steps: previousSteps,
      );
      isCallingOnFinish = true;
      await onFinish?.call(runResult);
      isCallingOnFinish = false;

      return runResult;
    } catch (error, stackTrace) {
      if (!isCallingOnFinish && _isCancelled(error)) {
        return _finishAbortedRun(
          previousSteps: previousSteps,
          activeRequest: activeRequest,
          activeStepNumber: activeStepNumber,
          activeResult: activeResult,
          reason: _cancelReason(error),
        );
      }

      final (reportedError, reportedStackTrace) =
          await _notifyError(error, stackTrace);
      Error.throwWithStackTrace(reportedError, reportedStackTrace);
    }
  }

  Future<GenerateTextRunResult> _finishAbortedRun({
    required List<GenerateTextStepResult> previousSteps,
    required GenerateTextRequest? activeRequest,
    required int? activeStepNumber,
    required GenerateTextResult? activeResult,
    required String? reason,
  }) async {
    if (activeRequest != null && activeStepNumber != null) {
      final abortedStep = GenerateTextStepResult(
        stepNumber: activeStepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: activeRequest,
        result: _abortedResult(activeResult, reason),
      );
      if (previousSteps.length == activeStepNumber) {
        previousSteps.add(abortedStep);
      } else if (previousSteps.length > activeStepNumber) {
        previousSteps[activeStepNumber] = abortedStep;
      }
      await onStepFinish?.call(abortedStep);
    } else if (previousSteps.isNotEmpty) {
      final lastStep = previousSteps.last;
      previousSteps[previousSteps.length - 1] = GenerateTextStepResult(
        stepNumber: lastStep.stepNumber,
        providerId: lastStep.providerId,
        modelId: lastStep.modelId,
        request: lastStep.request,
        result: _abortedResult(lastStep.result, reason),
      );
    }

    final runResult = GenerateTextRunResult(
      steps: previousSteps,
    );
    await onFinish?.call(runResult);
    return runResult;
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

Future<GenerateTextRunResult> runTextGeneration({
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
  GenerateTextOnError? onError,
}) {
  return GenerateTextRunner(
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
  ).run();
}
