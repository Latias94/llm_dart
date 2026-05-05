import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_run_result.dart';
import 'generate_text_runner_support.dart';
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
  final GenerateTextOnStepStart? onStepStart;
  final GenerateTextOnStepFinish? onStepFinish;
  final GenerateTextOnFinish? onFinish;

  GenerateTextRunner({
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
  })  : prompt = List.unmodifiable(prompt),
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

      final result = await model.generate(request);
      final step = GenerateTextStepResult(
        stepNumber: stepNumber,
        providerId: model.providerId,
        modelId: model.modelId,
        request: request,
        result: result,
      );
      await onStepFinish?.call(step);
      previousSteps.add(step);

      if (step.finishReason != FinishReason.toolCalls) {
        break;
      }

      final toolContinuation =
          await GenerateTextRunnerSupport.buildFunctionToolContinuation(
        step,
        declaredToolNames: declaredToolNames,
        functionToolExecutor: functionToolExecutor,
        runnerName: 'GenerateTextRunner',
      );
      if (toolContinuation == null) {
        break;
      }

      promptHistory = [
        ...promptHistory,
        ...GenerateTextRunnerSupport.stepToPromptMessages(
          step,
          runnerName: 'GenerateTextRunner',
        ),
        ...toolContinuation,
      ];
    }

    final runResult = GenerateTextRunResult(
      steps: previousSteps,
    );
    await onFinish?.call(runResult);

    return runResult;
  }
}

Future<GenerateTextRunResult> runTextGeneration({
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
}) {
  return GenerateTextRunner(
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
  ).run();
}
