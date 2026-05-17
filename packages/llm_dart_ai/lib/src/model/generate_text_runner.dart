import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import '../prompt/prompt_validation.dart';
import 'generate_text_run_lifecycle.dart';
import 'generate_text_run_result.dart';
import 'generate_text_run_state.dart';
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
    final state = GenerateTextRunState();
    final lifecycle = GenerateTextRunLifecycle(
      onStepFinish: onStepFinish,
      onFinish: onFinish,
      onError: onError,
      providerId: model.providerId,
      modelId: model.modelId,
    );

    try {
      var promptHistory = List<PromptMessage>.from(prompt);
      final declaredToolNames = {
        for (final tool in tools) tool.name,
      };

      while (true) {
        final stepNumber = state.nextStepNumber;
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
        state.beginStep(
          stepNumber: stepNumber,
          request: request,
        );

        final stepStartEvent = GenerateTextStepStartEvent(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          previousSteps: state.previousSteps,
        );
        await onStepStart?.call(stepStartEvent);
        _throwIfCancelled();

        final result = await model.doGenerate(request);
        state.setActiveResult(result);
        _throwIfCancelled();
        var step = GenerateTextStepResult(
          stepNumber: stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: request,
          result: result,
        );

        if (step.finishReason != FinishReason.toolCalls) {
          await lifecycle.finishStep(state, step);
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
          await lifecycle.finishStep(state, step);
          break;
        }

        step = GenerateTextRunnerSupport.addToolExecutionsToStep(
          step,
          toolExecutions,
        );
        await lifecycle.finishStep(state, step);

        if (await isStopConditionMet(
          stopConditions: stopWhen,
          steps: state.previousSteps,
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

      return lifecycle.finishSuccessfulRun(state);
    } catch (error, stackTrace) {
      if (!lifecycle.isCallingOnFinish && _isCancelled(error)) {
        return lifecycle.finishAbortedRun(
          state,
          reason: _cancelReason(error),
        );
      }

      final (reportedError, reportedStackTrace) =
          await lifecycle.notifyError(error, stackTrace);
      Error.throwWithStackTrace(reportedError, reportedStackTrace);
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
