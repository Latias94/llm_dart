import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import 'generate_text_run_lifecycle.dart';
import 'generate_text_run_result.dart';
import 'generate_text_run_state.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'generate_text_step_result.dart';
import 'text_generation_request.dart';
import 'text_generation_runtime_request.dart';

final class GenerateTextRunner {
  static const _runnerName = 'GenerateTextRunner';

  final TextGenerationRuntimeRequest _runtime;

  GenerateTextRunner._(this._runtime) {
    _runtime.validateForRunner(runnerName: _runnerName);
  }

  GenerateTextRunner.fromRequest(TextGenerationRequest request)
      : this._(TextGenerationRuntimeRequest.fromRequest(request));

  GenerateTextRunner({
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
  }) : this.fromRequest(
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
        );

  Future<GenerateTextRunResult> run() async {
    final state = GenerateTextRunState();
    final lifecycle = GenerateTextRunLifecycle(
      onStepFinish: _runtime.onStepFinish,
      onFinish: _runtime.onFinish,
      onError: _runtime.onError,
      providerId: _runtime.model.providerId,
      modelId: _runtime.model.modelId,
    );

    try {
      var promptHistory = _runtime.createPromptHistory();
      final stepContext = _runtime.createStepContext(runnerName: _runnerName);

      while (true) {
        final plan = stepContext.planner.planNextStep(
          promptHistory: promptHistory,
          previousSteps: state.previousSteps,
        );
        state.beginStep(
          stepNumber: plan.stepNumber,
          request: plan.request,
        );

        await _runtime.onStepStart?.call(plan.startEvent);
        _runtime.throwIfCancelled();

        final result = await _runtime.model.doGenerate(plan.request);
        state.setActiveResult(result);
        _runtime.throwIfCancelled();
        var step = GenerateTextStepResult(
          stepNumber: plan.stepNumber,
          providerId: _runtime.model.providerId,
          modelId: _runtime.model.modelId,
          request: plan.request,
          result: result,
        );

        final continuation = await stepContext.continuationResolver.resolve(
          step: step,
          promptHistory: promptHistory,
          finishStep: (step) async {
            await lifecycle.finishStep(state, step);
            return state.previousSteps;
          },
          throwIfCancelled: _runtime.throwIfCancelled,
        );
        if (!continuation.shouldContinue) {
          break;
        }
        promptHistory = continuation.promptHistory;
      }

      return lifecycle.finishSuccessfulRun(state);
    } catch (error, stackTrace) {
      if (!lifecycle.isCallingOnFinish && _runtime.isCancellation(error)) {
        return lifecycle.finishAbortedRun(
          state,
          reason: _runtime.cancellationReason(error),
        );
      }

      final (reportedError, reportedStackTrace) =
          await lifecycle.notifyError(error, stackTrace);
      Error.throwWithStackTrace(reportedError, reportedStackTrace);
    }
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
  return runTextGenerationRequest(
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
  );
}

Future<GenerateTextRunResult> runTextGenerationRequest(
  TextGenerationRequest request,
) {
  return GenerateTextRunner.fromRequest(request).run();
}
