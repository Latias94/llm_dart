import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'language_model.dart';
import 'output_spec.dart';
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
  if (outputSpec case final spec?) {
    final outputResult = await generateOutput(
      model: model,
      prompt: prompt,
      messages: messages,
      outputSpec: spec,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
      functionToolExecutor: functionToolExecutor,
      maxSteps: maxSteps,
      stopWhen: stopWhen,
    );
    return createGenerateTextCallResult<T>(
      result: outputResult.result,
      hasOutput: true,
      output: outputResult.output,
    );
  }

  final result = await generateText(
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
  if (outputSpec case final spec?) {
    return StreamTextCallResult<T>.structured(
      streamOutputResult(
        model: model,
        prompt: prompt,
        messages: messages,
        outputSpec: spec,
        tools: tools,
        toolChoice: toolChoice,
        options: options,
        callOptions: callOptions,
        functionToolExecutor: functionToolExecutor,
        maxSteps: maxSteps,
        stopWhen: stopWhen,
      ),
    );
  }

  return StreamTextCallResult<T>.raw(
    streamText(
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
    ),
  );
}
