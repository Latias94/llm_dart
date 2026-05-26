import 'package:llm_dart_provider/foundation.dart';

import '../model/generate_text_runner_support.dart';
import '../model/generate_text_stop_condition.dart';
import '../model/language_model.dart' as runtime;
import '../model/output_runner.dart' as output_runner;
import '../model/output_spec_foundation.dart';
import '../model/output_spec_strategy.dart';
import '../model/output_stream_result.dart';
import '../model/text_call_result.dart';
import '../model/text_call_runner.dart' as text_call_runner;
import '../model/text_generation_request.dart';
import '../prompt/model_message.dart';
import '../stream/text_stream_event.dart';

Future<GenerateTextResult> generateText({
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
  return runtime.generateTextForRequest(
    TextGenerationRequest.fromMessages(
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
    ),
  );
}

Stream<TextStreamEvent> streamText({
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
  StreamTextOnChunk? onChunk,
  GenerateTextOnError? onError,
}) {
  return runtime.streamTextForRequest(
    TextGenerationRequest.fromMessages(
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
    ),
    onChunk: onChunk,
  );
}

Future<GenerateTextCallResult<T>> generateTextCall<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
  OutputSpec<T>? outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return text_call_runner.generateTextCallForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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

StreamTextCallResult<T> streamTextCall<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
  OutputSpec<T>? outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return text_call_runner.streamTextCallForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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

Future<GenerateObjectResult<T>> generateObject<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
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
  return output_runner.generateOutputForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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
  required List<ModelMessage> messages,
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
  return output_runner.streamOutputResultForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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
  required List<ModelMessage> messages,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return output_runner.generateOutputForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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

Stream<OutputStreamEvent<T>> streamOutput<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return output_runner.streamOutputForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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

StreamOutputResult<T> streamOutputResult<T>({
  required LanguageModel model,
  required List<ModelMessage> messages,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
  GenerateTextFunctionToolExecutor? functionToolExecutor,
  int maxSteps = 8,
  Iterable<GenerateTextStopCondition> stopWhen = const [],
}) {
  return output_runner.streamOutputResultForRequest<T>(
    TextGenerationRequest.fromMessages(
      model: model,
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

T _identityObjectDecoder<T>(Map<String, Object?> json) {
  return json as T;
}
