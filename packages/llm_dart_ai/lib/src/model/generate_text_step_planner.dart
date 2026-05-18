import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/prompt_validation.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';

final class GenerateTextStepPlan {
  final int stepNumber;
  final GenerateTextRequest request;
  final GenerateTextStepStartEvent startEvent;

  const GenerateTextStepPlan({
    required this.stepNumber,
    required this.request,
    required this.startEvent,
  });
}

final class GenerateTextStepPlanner {
  final String runnerName;
  final LanguageModel model;
  final List<FunctionToolDefinition> tools;
  final ToolChoice? toolChoice;
  final GenerateTextOptions options;
  final CallOptions callOptions;
  final int maxSteps;

  GenerateTextStepPlanner({
    required this.runnerName,
    required this.model,
    List<FunctionToolDefinition> tools = const [],
    this.toolChoice,
    this.options = const GenerateTextOptions(),
    this.callOptions = const CallOptions(),
    this.maxSteps = 8,
  }) : tools = List.unmodifiable(tools) {
    validateMaxSteps(
      runnerName: runnerName,
      maxSteps: maxSteps,
    );
  }

  Set<String> get declaredToolNames => {
        for (final tool in tools) tool.name,
      };

  static void validateMaxSteps({
    required String runnerName,
    required int maxSteps,
  }) {
    if (maxSteps < 1) {
      throw ArgumentError.value(
        maxSteps,
        'maxSteps',
        '$runnerName.maxSteps must be at least 1.',
      );
    }
  }

  static void validatePromptForRunner({
    required String runnerName,
    required List<PromptMessage> prompt,
  }) {
    validateProviderPrompt(
      prompt,
      context: '$runnerName.prompt',
    );
  }

  GenerateTextStepPlan planNextStep({
    required List<PromptMessage> promptHistory,
    required List<GenerateTextStepResult> previousSteps,
  }) {
    final stepNumber = previousSteps.length;
    if (stepNumber >= maxSteps) {
      throw StateError(
        '$runnerName exceeded maxSteps ($maxSteps).',
      );
    }

    validatePrompt(
      promptHistory,
    );

    final request = GenerateTextRequest(
      prompt: promptHistory,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    );

    return GenerateTextStepPlan(
      stepNumber: stepNumber,
      request: request,
      startEvent: GenerateTextStepStartEvent(
        stepNumber: stepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: request,
        previousSteps: previousSteps,
      ),
    );
  }

  void validatePrompt(List<PromptMessage> prompt) {
    validatePromptForRunner(
      runnerName: runnerName,
      prompt: prompt,
    );
  }
}
