import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import 'generate_text_run_lifecycle.dart';
import 'generate_text_run_result.dart';
import 'generate_text_run_state.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_step_continuation_resolver.dart';
import 'generate_text_step_planner.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';

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
    GenerateTextStepPlanner.validateMaxSteps(
      runnerName: 'GenerateTextRunner',
      maxSteps: maxSteps,
    );
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
      final planner = GenerateTextStepPlanner(
        runnerName: 'GenerateTextRunner',
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
        runnerName: 'GenerateTextRunner',
      );

      while (true) {
        final plan = planner.planNextStep(
          promptHistory: promptHistory,
          previousSteps: state.previousSteps,
        );
        state.beginStep(
          stepNumber: plan.stepNumber,
          request: plan.request,
        );

        await onStepStart?.call(plan.startEvent);
        _throwIfCancelled();

        final result = await model.doGenerate(plan.request);
        state.setActiveResult(result);
        _throwIfCancelled();
        var step = GenerateTextStepResult(
          stepNumber: plan.stepNumber,
          providerId: model.providerId,
          modelId: model.modelId,
          request: plan.request,
          result: result,
        );

        final continuation = await continuationResolver.resolve(
          step: step,
          promptHistory: promptHistory,
          finishStep: (step) async {
            await lifecycle.finishStep(state, step);
            return state.previousSteps;
          },
          throwIfCancelled: _throwIfCancelled,
        );
        if (!continuation.shouldContinue) {
          break;
        }
        promptHistory = continuation.promptHistory;
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
