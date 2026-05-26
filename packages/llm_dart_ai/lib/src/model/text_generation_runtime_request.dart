import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import '../prompt/prompt_normalization.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_step_continuation_resolver.dart';
import 'generate_text_step_planner.dart';
import 'generate_text_stop_condition.dart';
import 'text_generation_request.dart';

final class TextGenerationRuntimeStepContext {
  final GenerateTextStepPlanner planner;
  final GenerateTextStepContinuationResolver continuationResolver;

  const TextGenerationRuntimeStepContext({
    required this.planner,
    required this.continuationResolver,
  });
}

final class TextGenerationRuntimeRequest {
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

  TextGenerationRuntimeRequest({
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
  })  : prompt = resolveProviderPrompt(
          prompt: prompt,
          messages: messages,
        ),
        tools = List.unmodifiable(tools),
        stopWhen = List.unmodifiable(stopWhen);

  factory TextGenerationRuntimeRequest.fromRequest(
    TextGenerationRequest request,
  ) {
    return TextGenerationRuntimeRequest(
      model: request.model,
      prompt: request.prompt,
      messages: request.messages,
      tools: request.tools,
      toolChoice: request.toolChoice,
      options: request.options,
      callOptions: request.callOptions,
      functionToolExecutor: request.functionToolExecutor,
      maxSteps: request.maxSteps,
      stopWhen: request.stopWhen,
      onStepStart: request.onStepStart,
      onStepFinish: request.onStepFinish,
      onToolStart: request.onToolStart,
      onToolFinish: request.onToolFinish,
      onFinish: request.onFinish,
      onError: request.onError,
    );
  }

  TextGenerationRuntimeRequest withOptions(
    GenerateTextOptions options,
  ) {
    return TextGenerationRuntimeRequest(
      model: model,
      prompt: prompt,
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
    );
  }

  void validateForRunner({
    required String runnerName,
    bool validateInitialPrompt = false,
  }) {
    if (validateInitialPrompt) {
      GenerateTextStepPlanner.validatePromptForRunner(
        runnerName: runnerName,
        prompt: prompt,
      );
    }
    GenerateTextStepPlanner.validateMaxSteps(
      runnerName: runnerName,
      maxSteps: maxSteps,
    );
  }

  List<PromptMessage> createPromptHistory() {
    return List<PromptMessage>.from(prompt);
  }

  TextGenerationRuntimeStepContext createStepContext({
    required String runnerName,
  }) {
    final planner = GenerateTextStepPlanner(
      runnerName: runnerName,
      model: model,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
      maxSteps: maxSteps,
    );

    return TextGenerationRuntimeStepContext(
      planner: planner,
      continuationResolver: GenerateTextStepContinuationResolver(
        declaredToolNames: planner.declaredToolNames,
        functionToolExecutor: functionToolExecutor,
        onToolStart: onToolStart,
        onToolFinish: onToolFinish,
        stopConditions: stopWhen,
        runnerName: runnerName,
      ),
    );
  }

  void throwIfCancelled() {
    callOptions.cancellation?.throwIfCancelled();
  }

  bool isCancellation(Object error) {
    return ProviderCancellation.isCancel(error);
  }

  String? cancellationReason(Object error) {
    if (error is ProviderCancelledException) {
      return error.reason?.toString();
    }

    return callOptions.cancellation?.reason?.toString();
  }
}
