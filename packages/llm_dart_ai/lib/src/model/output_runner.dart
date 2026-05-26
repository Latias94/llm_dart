import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../prompt/model_message.dart';
import 'generate_text_result_accumulator.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'language_model.dart';
import 'output_runner_parsing.dart';
import 'output_spec_foundation.dart';
import 'output_spec_strategy.dart';
import 'output_stream_projection.dart';
import 'output_stream_result.dart';
import 'text_generation_request.dart';
import 'text_generation_runtime_request.dart';

Future<GenerateObjectResult<T>> generateObject<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  required JsonSchema schema,
  JsonObjectDecoder<T>? decode,
  String? name,
  String? description,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return generateOutputForRequest<T>(
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
    outputSpec: ObjectOutputSpec<T>(
      schema: schema,
      name: name,
      description: description,
      decode: decode ?? _identityObjectDecoder<T>,
    ),
  );
}

StreamObjectResult<T> streamObject<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  required JsonSchema schema,
  JsonObjectDecoder<T>? decode,
  String? name,
  String? description,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return streamOutputResultForRequest<T>(
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
    outputSpec: ObjectOutputSpec<T>(
      schema: schema,
      name: name,
      description: description,
      decode: decode ?? _identityObjectDecoder<T>,
    ),
  );
}

Future<GenerateOutputResult<T>> generateOutput<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) async {
  return generateOutputForRequest<T>(
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

Future<GenerateOutputResult<T>> generateOutputForRequest<T>(
  TextGenerationRequest request, {
  required OutputSpec<T> outputSpec,
}) async {
  validateOutputRunnerOptions(
    options: request.options,
    runnerName: 'generateOutput',
  );
  final runtime = TextGenerationRuntimeRequest.fromRequest(request);
  final outputRuntime = runtime.withOptions(
    withOutputResponseFormat(
      runtime.options,
      outputSpec.responseFormat,
    ),
  );

  final result = await generateTextForRequest(
    TextGenerationRequest.fromPrompt(
      model: outputRuntime.model,
      prompt: outputRuntime.prompt,
      tools: outputRuntime.tools,
      toolChoice: outputRuntime.toolChoice,
      options: outputRuntime.options,
      callOptions: outputRuntime.callOptions,
      functionToolExecutor: outputRuntime.functionToolExecutor,
      maxSteps: outputRuntime.maxSteps,
      stopWhen: outputRuntime.stopWhen,
      onStepStart: outputRuntime.onStepStart,
      onStepFinish: outputRuntime.onStepFinish,
      onToolStart: outputRuntime.onToolStart,
      onToolFinish: outputRuntime.onToolFinish,
      onFinish: outputRuntime.onFinish,
      onError: outputRuntime.onError,
    ),
  );

  return parseGenerateOutputResult(
    result: result,
    outputSpec: outputSpec,
    context: createStructuredOutputContext(result),
  );
}

Stream<OutputStreamEvent<T>> streamOutput<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) async* {
  yield* streamOutputForRequest<T>(
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

Stream<OutputStreamEvent<T>> streamOutputForRequest<T>(
  TextGenerationRequest request, {
  required OutputSpec<T> outputSpec,
}) async* {
  validateOutputRunnerOptions(
    options: request.options,
    runnerName: 'streamOutput',
  );
  final runtime = TextGenerationRuntimeRequest.fromRequest(request);
  final outputRuntime = runtime.withOptions(
    withOutputResponseFormat(
      runtime.options,
      outputSpec.responseFormat,
    ),
  );

  final accumulator = GenerateTextResultAccumulator();
  final projection = OutputStreamProjection<T>(
    outputSpec: outputSpec,
  );
  final events = streamTextForRequest(
    TextGenerationRequest.fromPrompt(
      model: outputRuntime.model,
      prompt: outputRuntime.prompt,
      tools: outputRuntime.tools,
      toolChoice: outputRuntime.toolChoice,
      options: outputRuntime.options,
      callOptions: outputRuntime.callOptions,
      functionToolExecutor: outputRuntime.functionToolExecutor,
      maxSteps: outputRuntime.maxSteps,
      stopWhen: outputRuntime.stopWhen,
      onStepStart: outputRuntime.onStepStart,
      onStepFinish: outputRuntime.onStepFinish,
      onToolStart: outputRuntime.onToolStart,
      onToolFinish: outputRuntime.onToolFinish,
      onFinish: outputRuntime.onFinish,
      onError: outputRuntime.onError,
    ),
  );

  await for (final event in events) {
    accumulator.apply(event);
    yield OutputTextStreamEvent<T>(event);

    for (final outputEvent in await projection.project(
      event,
      text: accumulator.text,
    )) {
      yield outputEvent;
    }
  }

  final result = accumulator.build();
  yield OutputFinishEvent<T>(result);

  try {
    yield OutputResultEvent<T>(
      await parseGenerateOutputResult(
        result: result,
        outputSpec: outputSpec,
        context: createStructuredOutputContext(result),
      ),
    );
  } catch (error, stackTrace) {
    yield OutputErrorEvent<T>(
      modelErrorFrom(
        error,
        kind: ModelErrorKind.validation,
      ),
      stackTrace: stackTrace,
    );
  }
}

StreamOutputResult<T> streamOutputResult<T>({
  required LanguageModel model,
  List<PromptMessage>? prompt,
  List<ModelMessage>? messages,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return createStreamOutputResult<T>(
    streamOutputForRequest(
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
    ),
  );
}

StreamOutputResult<T> streamOutputResultForRequest<T>(
  TextGenerationRequest request, {
  required OutputSpec<T> outputSpec,
}) {
  return createStreamOutputResult<T>(
    streamOutputForRequest(
      request,
      outputSpec: outputSpec,
    ),
  );
}

T _identityObjectDecoder<T>(Map<String, Object?> json) {
  return json as T;
}
