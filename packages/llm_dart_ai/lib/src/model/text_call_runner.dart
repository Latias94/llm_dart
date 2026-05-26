import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'language_model.dart';
import 'output_spec.dart';
import 'text_generation_request.dart';
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
  return generateTextCallForRequest<T>(
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
    ),
    outputSpec: outputSpec,
  );
}

Future<GenerateTextCallResult<T>> generateTextCallForRequest<T>(
  TextGenerationRequest request, {
  OutputSpec<T>? outputSpec,
}) async {
  if (outputSpec case final spec?) {
    final outputResult = await generateOutputForRequest(
      request,
      outputSpec: spec,
    );
    return createGenerateTextCallResult<T>(
      result: outputResult.result,
      hasOutput: true,
      output: outputResult.output,
    );
  }

  final result = await generateTextForRequest(request);

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
  return streamTextCallForRequest<T>(
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
    ),
    outputSpec: outputSpec,
  );
}

StreamTextCallResult<T> streamTextCallForRequest<T>(
  TextGenerationRequest request, {
  OutputSpec<T>? outputSpec,
}) {
  if (outputSpec case final spec?) {
    return StreamTextCallResult<T>.structured(
      streamOutputResultForRequest(
        request,
        outputSpec: spec,
      ),
    );
  }

  return StreamTextCallResult<T>.raw(
    streamTextForRequest(request),
  );
}
