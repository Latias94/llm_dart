import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';

final class TextGenerationRequest {
  final LanguageModel model;
  final List<PromptMessage>? prompt;
  final List<ModelMessage>? messages;
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

  TextGenerationRequest._({
    required this.model,
    this.prompt,
    this.messages,
    required List<FunctionToolDefinition> tools,
    this.toolChoice,
    required this.options,
    required this.callOptions,
    this.functionToolExecutor,
    required this.maxSteps,
    required Iterable<GenerateTextStopCondition> stopWhen,
    this.onStepStart,
    this.onStepFinish,
    this.onToolStart,
    this.onToolFinish,
    this.onFinish,
    this.onError,
  })  : tools = List.unmodifiable(tools),
        stopWhen = List.unmodifiable(stopWhen);

  factory TextGenerationRequest.fromPrompt({
    required LanguageModel model,
    required List<PromptMessage> prompt,
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
    return TextGenerationRequest._(
      model: model,
      prompt: List.unmodifiable(prompt),
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

  factory TextGenerationRequest.fromMessages({
    required LanguageModel model,
    required List<ModelMessage> messages,
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
    return TextGenerationRequest._(
      model: model,
      messages: List.unmodifiable(messages),
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

  factory TextGenerationRequest.resolve({
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
    if (prompt != null && messages != null) {
      throw ArgumentError(
        'Provide either provider-facing prompt or user-facing messages, not both.',
      );
    }

    if (prompt != null) {
      return TextGenerationRequest.fromPrompt(
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

    if (messages != null) {
      return TextGenerationRequest.fromMessages(
        model: model,
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
      );
    }

    throw ArgumentError(
      'Provide either provider-facing prompt or user-facing messages.',
    );
  }

  TextGenerationRequest withOptions(GenerateTextOptions options) {
    final providerPrompt = prompt;
    if (providerPrompt != null) {
      return TextGenerationRequest.fromPrompt(
        model: model,
        prompt: providerPrompt,
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

    return TextGenerationRequest.fromMessages(
      model: model,
      messages: messages!,
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
}
