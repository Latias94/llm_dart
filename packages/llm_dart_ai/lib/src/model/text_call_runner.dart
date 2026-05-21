import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'language_model.dart';
import 'output_spec.dart';
import 'text_generation_runtime_request.dart';
import 'text_call_result.dart';

Future<GenerateTextCallResult<T>> generateTextCall<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  OutputSpec<T>? outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) async {
  final runtime = TextGenerationRuntimeRequest(
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
  );

  if (outputSpec case final spec?) {
    final outputResult = await generateOutput(
      model: runtime.model,
      prompt: runtime.prompt,
      outputSpec: spec,
      tools: runtime.tools,
      toolChoice: runtime.toolChoice,
      options: runtime.options,
      callOptions: runtime.callOptions,
      functionToolExecutor: runtime.functionToolExecutor,
      maxSteps: runtime.maxSteps,
      stopWhen: runtime.stopWhen,
    );
    return createGenerateTextCallResult<T>(
      result: outputResult.result,
      hasOutput: true,
      output: outputResult.output,
    );
  }

  final result = await generateText(
    model: runtime.model,
    prompt: runtime.prompt,
    tools: runtime.tools,
    toolChoice: runtime.toolChoice,
    options: runtime.options,
    callOptions: runtime.callOptions,
    functionToolExecutor: runtime.functionToolExecutor,
    maxSteps: runtime.maxSteps,
    stopWhen: runtime.stopWhen,
  );

  return createGenerateTextCallResult<T>(
    result: result,
    hasOutput: false,
  );
}

StreamTextCallResult<T> streamTextCall<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  OutputSpec<T>? outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  final runtime = TextGenerationRuntimeRequest(
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
  );

  if (outputSpec case final spec?) {
    return StreamTextCallResult<T>.structured(
      streamOutputResult(
        model: runtime.model,
        prompt: runtime.prompt,
        outputSpec: spec,
        tools: runtime.tools,
        toolChoice: runtime.toolChoice,
        options: runtime.options,
        callOptions: runtime.callOptions,
        functionToolExecutor: runtime.functionToolExecutor,
        maxSteps: runtime.maxSteps,
        stopWhen: runtime.stopWhen,
      ),
    );
  }

  return StreamTextCallResult<T>.raw(
    streamText(
      model: runtime.model,
      prompt: runtime.prompt,
      tools: runtime.tools,
      toolChoice: runtime.toolChoice,
      options: runtime.options,
      callOptions: runtime.callOptions,
      functionToolExecutor: runtime.functionToolExecutor,
      maxSteps: runtime.maxSteps,
      stopWhen: runtime.stopWhen,
    ),
  );
}
