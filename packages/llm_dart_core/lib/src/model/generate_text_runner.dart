import 'dart:async';

import '../common/call_options.dart';
import '../prompt/prompt_message.dart';
import '../tool/tool_definition.dart';
import 'generate_text_run_result.dart';
import 'generate_text_step_result.dart';
import 'generate_text_step_start_event.dart';
import 'language_model.dart';

typedef GenerateTextOnStepStart = FutureOr<void> Function(
  GenerateTextStepStartEvent event,
);

typedef GenerateTextOnStepFinish = FutureOr<void> Function(
  GenerateTextStepResult step,
);

typedef GenerateTextOnFinish = FutureOr<void> Function(
  GenerateTextRunResult result,
);

final class GenerateTextRunner {
  final LanguageModel model;
  final List<PromptMessage> prompt;
  final List<FunctionToolDefinition> tools;
  final ToolChoice? toolChoice;
  final GenerateTextOptions options;
  final CallOptions callOptions;
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
    this.onStepStart,
    this.onStepFinish,
    this.onFinish,
  })  : prompt = List.unmodifiable(prompt),
        tools = List.unmodifiable(tools);

  Future<GenerateTextRunResult> run() async {
    final request = GenerateTextRequest(
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
    );

    final stepStartEvent = GenerateTextStepStartEvent(
      stepNumber: 0,
      providerId: model.providerId,
      modelId: model.modelId,
      request: request,
    );
    await onStepStart?.call(stepStartEvent);

    final result = await model.generate(request);
    final step = GenerateTextStepResult(
      stepNumber: 0,
      providerId: model.providerId,
      modelId: model.modelId,
      request: request,
      result: result,
    );
    await onStepFinish?.call(step);

    final runResult = GenerateTextRunResult(
      steps: [step],
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
    onStepStart: onStepStart,
    onStepFinish: onStepFinish,
    onFinish: onFinish,
  ).run();
}
