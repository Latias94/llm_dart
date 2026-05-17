import '../prompt/model_message.dart';
import '../stream/text_stream_event.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide TextDeltaEvent, TextEndEvent;

import 'generate_text_result_accumulator.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'language_model.dart';
import 'output_spec_foundation.dart';
import 'output_spec_json.dart';
import 'output_spec_strategy.dart';
import 'output_stream_result.dart';

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
  return generateOutput<T>(
    model: model,
    prompt: prompt,
    messages: messages,
    outputSpec: ObjectOutputSpec<T>(
      schema: schema,
      name: name,
      description: description,
      decode: decode ?? _identityObjectDecoder<T>,
    ),
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    stopWhen: stopWhen,
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
  return streamOutputResult<T>(
    model: model,
    prompt: prompt,
    messages: messages,
    outputSpec: ObjectOutputSpec<T>(
      schema: schema,
      name: name,
      description: description,
      decode: decode ?? _identityObjectDecoder<T>,
    ),
    tools: tools,
    toolChoice: toolChoice,
    options: options,
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    stopWhen: stopWhen,
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
  if (options.responseFormat != null) {
    throw ArgumentError(
      'generateOutput uses OutputSpec.responseFormat and does not allow GenerateTextOptions.responseFormat at the same time.',
    );
  }

  final result = await generateText(
    model: model,
    prompt: prompt,
    messages: messages,
    tools: tools,
    toolChoice: toolChoice,
    options: _withResponseFormat(
      options,
      outputSpec.responseFormat,
    ),
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    stopWhen: stopWhen,
  );

  final context = createStructuredOutputContext(result);
  return parseGenerateOutputResult(
    result: result,
    outputSpec: outputSpec,
    context: context,
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
  if (options.responseFormat != null) {
    throw ArgumentError(
      'streamOutput uses OutputSpec.responseFormat and does not allow GenerateTextOptions.responseFormat at the same time.',
    );
  }

  final accumulator = GenerateTextResultAccumulator();
  final events = streamText(
    model: model,
    prompt: prompt,
    messages: messages,
    tools: tools,
    toolChoice: toolChoice,
    options: _withResponseFormat(
      options,
      outputSpec.responseFormat,
    ),
    callOptions: callOptions,
    functionToolExecutor: functionToolExecutor,
    maxSteps: maxSteps,
    stopWhen: stopWhen,
  );

  Object? lastPartialOutput;
  var hasPartialOutput = false;

  await for (final event in events) {
    accumulator.apply(event);
    yield OutputTextStreamEvent<T>(event);

    if (event is TextDeltaEvent || event is TextEndEvent) {
      final partialOutput = await tryParsePartialOutput(
        outputSpec: outputSpec,
        text: accumulator.text,
      );

      if (partialOutput != null &&
          (!hasPartialOutput ||
              !structuredOutputValueEquals(
                lastPartialOutput,
                partialOutput,
              ))) {
        final previousPartialOutput = lastPartialOutput;
        hasPartialOutput = true;
        lastPartialOutput = partialOutput;
        yield OutputPartialEvent<T>(partialOutput);
        for (final elementEvent in outputSpec.createElementEvents(
          partialOutput: partialOutput,
          previousPartialOutput: previousPartialOutput,
        )) {
          yield elementEvent;
        }
      }
    }
  }

  final result = accumulator.build();
  final context = createStructuredOutputContext(result);
  yield OutputResultEvent<T>(
    await parseGenerateOutputResult(
      result: result,
      outputSpec: outputSpec,
      context: context,
    ),
  );
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
    streamOutput(
      model: model,
      prompt: prompt,
      messages: messages,
      outputSpec: outputSpec,
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

StructuredOutputContext createStructuredOutputContext(
  GenerateTextResult result,
) {
  return StructuredOutputContext(
    responseId: result.responseId,
    responseTimestamp: result.responseTimestamp,
    responseModelId: result.responseModelId,
    finishReason: result.finishReason,
    rawFinishReason: result.rawFinishReason,
    usage: result.usage,
    providerMetadata: result.providerMetadata,
  );
}

Future<GenerateOutputResult<T>> parseGenerateOutputResult<T>({
  required GenerateTextResult result,
  required OutputSpec<T> outputSpec,
  required StructuredOutputContext context,
}) async {
  try {
    final output = await outputSpec.parse(
      text: result.text,
      context: context,
    );
    return GenerateOutputResult(
      result: result,
      output: output,
    );
  } catch (error) {
    throw ModelError.fromUnknown(
      error,
      kind: ModelErrorKind.validation,
      details: structuredOutputErrorDetails(
        text: result.text,
        context: context,
      ),
    );
  }
}

Future<Object?> tryParsePartialOutput<T>({
  required OutputSpec<T> outputSpec,
  required String text,
}) async {
  try {
    return await outputSpec.parsePartial(text: text);
  } catch (_) {
    return null;
  }
}

Map<String, Object?> structuredOutputErrorDetails({
  required String text,
  required StructuredOutputContext context,
}) {
  return {
    'stage': 'structured_output',
    'text': text,
    if (context.responseId != null) 'responseId': context.responseId,
    if (context.responseTimestamp != null)
      'responseTimestamp': context.responseTimestamp!.toIso8601String(),
    if (context.responseModelId != null)
      'responseModelId': context.responseModelId,
    'finishReason': context.finishReason.name,
    if (context.rawFinishReason != null)
      'rawFinishReason': context.rawFinishReason,
    if (context.usage != null)
      'usage': structuredOutputUsageToJson(context.usage!),
    if (context.providerMetadata != null)
      'providerMetadata': context.providerMetadata!.toJsonMap(),
  };
}

GenerateTextOptions _withResponseFormat(
  GenerateTextOptions options,
  ResponseFormat? responseFormat,
) {
  return GenerateTextOptions(
    maxOutputTokens: options.maxOutputTokens,
    temperature: options.temperature,
    stopSequences: options.stopSequences,
    topP: options.topP,
    topK: options.topK,
    presencePenalty: options.presencePenalty,
    frequencyPenalty: options.frequencyPenalty,
    seed: options.seed,
    reasoning: options.reasoning,
    includeRawChunks: options.includeRawChunks,
    responseFormat: responseFormat,
  );
}

T _identityObjectDecoder<T>(Map<String, Object?> json) {
  return json as T;
}
