import 'dart:async';
import 'dart:convert';

import '../common/partial_json.dart';
import '../prompt/model_message.dart';
import '../stream/text_stream_event.dart';
import '../ui/chat_ui_message.dart';
import '../ui/chat_ui_stream_chunk.dart';
import '../ui/chat_ui_stream_projection.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart'
    hide TextDeltaEvent, TextEndEvent;

import 'generate_text_result_accumulator.dart';
import 'generate_text_runner_support.dart';
import 'generate_text_stop_condition.dart';
import 'language_model.dart';
import 'stream_result_foundation.dart';

typedef JsonOutputDecoder<T> = T Function(Object? json);
typedef JsonObjectDecoder<T> = T Function(Map<String, Object?> json);
typedef JsonArrayElementDecoder<T> = T Function(Object? json);

final class StructuredOutputContext {
  final String? responseId;
  final DateTime? responseTimestamp;
  final String? responseModelId;
  final FinishReason finishReason;
  final String? rawFinishReason;
  final UsageStats? usage;
  final ProviderMetadata? providerMetadata;

  const StructuredOutputContext({
    this.responseId,
    this.responseTimestamp,
    this.responseModelId,
    required this.finishReason,
    this.rawFinishReason,
    this.usage,
    this.providerMetadata,
  });
}

abstract class OutputSpec<T> {
  const OutputSpec();

  ResponseFormat? get responseFormat;

  FutureOr<T> parse({
    required String text,
    required StructuredOutputContext context,
  });

  FutureOr<Object?> parsePartial({
    required String text,
  }) {
    return null;
  }

  Iterable<OutputStreamEvent<T>> createElementEvents({
    required Object partialOutput,
    required Object? previousPartialOutput,
  }) sync* {}
}

final class TextOutputSpec extends OutputSpec<String> {
  const TextOutputSpec();

  @override
  ResponseFormat get responseFormat => const TextResponseFormat();

  @override
  String parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    return text;
  }

  @override
  String parsePartial({
    required String text,
  }) {
    return text;
  }
}

final class JsonOutputSpec<T> extends OutputSpec<T> {
  final JsonSchema schema;
  final String? name;
  final String? description;
  final JsonOutputDecoder<T> decode;

  const JsonOutputSpec({
    required this.schema,
    required this.decode,
    this.name,
    this.description,
  });

  static JsonOutputSpec<Object?> json({
    required JsonSchema schema,
    String? name,
    String? description,
  }) {
    return JsonOutputSpec<Object?>(
      schema: schema,
      name: name,
      description: description,
      decode: (json) => json,
    );
  }

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: schema,
        name: name,
        description: description,
      );

  @override
  T parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = _decodeJsonText(text);
    return decode(json);
  }

  @override
  Object? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    return switch (result.state) {
      PartialJsonParseState.undefinedInput ||
      PartialJsonParseState.failedParse =>
        null,
      PartialJsonParseState.successfulParse ||
      PartialJsonParseState.repairedParse =>
        _freezeJsonValue(result.value),
    };
  }
}

final class ObjectOutputSpec<T> extends OutputSpec<T> {
  final JsonSchema schema;
  final String? name;
  final String? description;
  final JsonObjectDecoder<T> decode;

  ObjectOutputSpec({
    required JsonSchema schema,
    required this.decode,
    this.name,
    this.description,
  }) : schema = _validateObjectSchema(schema);

  static ObjectOutputSpec<Map<String, Object?>> json({
    required JsonSchema schema,
    String? name,
    String? description,
  }) {
    return ObjectOutputSpec<Map<String, Object?>>(
      schema: schema,
      name: name,
      description: description,
      decode: (json) => json,
    );
  }

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: schema,
        name: name,
        description: description,
      );

  @override
  T parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = _decodeJsonText(text);
    final object = _requireJsonObject(
      json,
      message:
          'Could not parse structured output object: expected a JSON object root.',
    );
    return decode(object);
  }

  @override
  Map<String, Object?>? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    return switch (result.state) {
      PartialJsonParseState.undefinedInput ||
      PartialJsonParseState.failedParse =>
        null,
      PartialJsonParseState.successfulParse ||
      PartialJsonParseState.repairedParse =>
        _tryRequireJsonObject(result.value),
    };
  }
}

final class ArrayOutputSpec<T> extends OutputSpec<List<T>> {
  final JsonSchema elementSchema;
  final String? name;
  final String? description;
  final JsonArrayElementDecoder<T> decodeElement;

  const ArrayOutputSpec({
    required this.elementSchema,
    required this.decodeElement,
    this.name,
    this.description,
  });

  static ArrayOutputSpec<Object?> json({
    required JsonSchema elementSchema,
    String? name,
    String? description,
  }) {
    return ArrayOutputSpec<Object?>(
      elementSchema: elementSchema,
      name: name,
      description: description,
      decodeElement: (json) => json,
    );
  }

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: JsonSchema.object(
          properties: {
            'elements': JsonSchema.array(
              items: elementSchema.toJson(),
            ).toJson(),
          },
          required: const ['elements'],
          additionalProperties: false,
        ),
        name: name,
        description: description,
      );

  @override
  List<T> parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = _decodeJsonText(text);
    final object = _requireJsonObject(
      json,
      message:
          'Could not parse structured output array: expected an object with an "elements" array.',
    );
    final rawElements = object['elements'];
    if (rawElements is! List) {
      throw const FormatException(
        'Could not parse structured output array: expected an "elements" array.',
      );
    }

    return List<T>.unmodifiable(
      rawElements.map(decodeElement),
    );
  }

  @override
  List<T>? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    switch (result.state) {
      case PartialJsonParseState.undefinedInput ||
            PartialJsonParseState.failedParse:
        return null;
      case PartialJsonParseState.successfulParse ||
            PartialJsonParseState.repairedParse:
        final object = _tryRequireJsonObject(result.value);
        final rawElements = object?['elements'];
        if (rawElements is! List) {
          return null;
        }

        final candidateElements =
            result.state == PartialJsonParseState.repairedParse &&
                    rawElements.isNotEmpty
                ? rawElements.take(rawElements.length - 1)
                : rawElements;

        final parsedElements = <T>[];
        for (final rawElement in candidateElements) {
          try {
            parsedElements.add(decodeElement(rawElement));
          } catch (_) {
            continue;
          }
        }

        return List<T>.unmodifiable(parsedElements);
    }
  }

  @override
  Iterable<OutputStreamEvent<List<T>>> createElementEvents({
    required Object partialOutput,
    required Object? previousPartialOutput,
  }) sync* {
    final partial = partialOutput as List<T>;
    final previous = previousPartialOutput as List<T>?;
    final previousLength = previous?.length ?? 0;

    if (partial.length < previousLength) {
      return;
    }

    for (var index = previousLength; index < partial.length; index++) {
      yield OutputElementEvent<T>(partial[index]);
    }
  }
}

final class ChoiceOutputSpec<T extends String> extends OutputSpec<T> {
  final List<T> options;
  final String? name;
  final String? description;

  ChoiceOutputSpec({
    required List<T> options,
    this.name,
    this.description,
  }) : options = _normalizeChoiceOptions(options);

  @override
  ResponseFormat get responseFormat => JsonResponseFormat(
        schema: JsonSchema.object(
          properties: {
            'result': JsonSchema.string(
              enumValues: options,
            ).toJson(),
          },
          required: const ['result'],
          additionalProperties: false,
        ),
        name: name,
        description: description,
      );

  @override
  T parse({
    required String text,
    required StructuredOutputContext context,
  }) {
    final json = _decodeJsonText(text);
    final object = _requireJsonObject(
      json,
      message:
          'Could not parse structured output choice: expected an object with a "result" field.',
    );
    final value = object['result'];
    if (value is! String) {
      throw const FormatException(
        'Could not parse structured output choice: expected a string "result" value.',
      );
    }

    for (final option in options) {
      if (option == value) {
        return option;
      }
    }

    throw FormatException(
      'Could not parse structured output choice: expected one of ${options.join(', ')}.',
    );
  }

  @override
  T? parsePartial({
    required String text,
  }) {
    final result = parsePartialJson(text);
    switch (result.state) {
      case PartialJsonParseState.undefinedInput ||
            PartialJsonParseState.failedParse:
        return null;
      case PartialJsonParseState.successfulParse ||
            PartialJsonParseState.repairedParse:
        final object = _tryRequireJsonObject(result.value);
        final value = object?['result'];
        if (value is! String) {
          return null;
        }

        final potentialMatches = options
            .where((option) => option.startsWith(value))
            .toList(growable: false);

        if (result.state == PartialJsonParseState.successfulParse) {
          return potentialMatches.contains(value)
              ? potentialMatches.firstWhere((option) => option == value)
              : null;
        }

        return potentialMatches.length == 1 ? potentialMatches.single : null;
    }
  }
}

final class GenerateOutputResult<T> {
  final GenerateTextResult result;
  final T output;

  const GenerateOutputResult({
    required this.result,
    required this.output,
  });

  String get text => result.text;

  String? get reasoningText => result.reasoningText;

  FinishReason get finishReason => result.finishReason;

  String? get rawFinishReason => result.rawFinishReason;

  String? get responseId => result.responseId;

  DateTime? get responseTimestamp => result.responseTimestamp;

  String? get responseModelId => result.responseModelId;

  UsageStats? get usage => result.usage;

  ProviderMetadata? get providerMetadata => result.providerMetadata;
}

typedef GenerateObjectResult<T> = GenerateOutputResult<T>;

sealed class OutputStreamEvent<T> {
  const OutputStreamEvent();
}

final class OutputTextStreamEvent<T> extends OutputStreamEvent<T> {
  final TextStreamEvent streamEvent;

  const OutputTextStreamEvent(this.streamEvent);
}

final class OutputPartialEvent<T> extends OutputStreamEvent<T> {
  final Object? partialOutput;

  const OutputPartialEvent(this.partialOutput);
}

final class OutputElementEvent<T> extends OutputStreamEvent<List<T>> {
  final T element;

  const OutputElementEvent(this.element);
}

final class OutputResultEvent<T> extends OutputStreamEvent<T> {
  final GenerateOutputResult<T> result;

  const OutputResultEvent(this.result);
}

final class StreamOutputResult<T> {
  final StreamResultController<OutputStreamEvent<T>, GenerateOutputResult<T>>
      _foundation =
      StreamResultController<OutputStreamEvent<T>, GenerateOutputResult<T>>();
  late final StreamSideChannel<Object?> _partialOutputChannel;
  late final StreamSideChannel<Object?> _elementChannel;

  StreamOutputResult._(Stream<OutputStreamEvent<T>> source) {
    _partialOutputChannel = _foundation.createSideChannel<Object?>();
    _elementChannel = _foundation.createSideChannel<Object?>();
    source.listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: true,
    );
  }

  Stream<OutputStreamEvent<T>> get eventStream => _foundation.eventStream;

  Stream<TextStreamEvent> get textStream =>
      eventStream.transform<TextStreamEvent>(
        StreamTransformer<OutputStreamEvent<T>, TextStreamEvent>.fromHandlers(
          handleData: (event, sink) {
            if (event case OutputTextStreamEvent<T>(:final streamEvent)) {
              sink.add(streamEvent);
            }
          },
        ),
      );

  Stream<Object?> get partialOutputStream => _partialOutputChannel.stream;

  Stream<TElement> elementStream<TElement>() =>
      _elementChannel.stream.cast<TElement>();

  Stream<ChatUiStreamChunk> chatUiStream({
    String? messageId,
    Map<String, Object?> messageMetadata = const {},
    Iterable<DataUiPart<Object?>> leadingDataParts = const [],
    Map<String, Object?> finalMessageMetadata = const {},
  }) {
    return projectTextStreamEventStream(
      textStream,
      messageId: messageId,
      messageMetadata: messageMetadata,
      leadingDataParts: leadingDataParts,
      finalMessageMetadata: finalMessageMetadata,
    );
  }

  Future<GenerateOutputResult<T>> get result => _foundation.result;

  Future<T> get output => result.then((value) => value.output);

  Future<String> get text => result.then((value) => value.text);

  Future<String?> get reasoningText =>
      result.then((value) => value.reasoningText);

  Future<FinishReason> get finishReason =>
      result.then((value) => value.finishReason);

  Future<String?> get rawFinishReason =>
      result.then((value) => value.rawFinishReason);

  Future<String?> get responseId => result.then((value) => value.responseId);

  Future<DateTime?> get responseTimestamp =>
      result.then((value) => value.responseTimestamp);

  Future<String?> get responseModelId =>
      result.then((value) => value.responseModelId);

  Future<UsageStats?> get usage => result.then((value) => value.usage);

  Future<ProviderMetadata?> get providerMetadata =>
      result.then((value) => value.providerMetadata);

  void _handleEvent(OutputStreamEvent<T> event) {
    _foundation.addEvent(event);

    switch (event) {
      case OutputTextStreamEvent<T>():
        break;
      case OutputPartialEvent<T>(:final partialOutput):
        _partialOutputChannel.add(partialOutput);
      case OutputElementEvent(:final element):
        _elementChannel.add(element);
      case OutputResultEvent<T>(:final result):
        _foundation.completeResult(result);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _foundation.fail(error, stackTrace);
  }

  void _handleDone() {
    if (!_foundation.isResultCompleted) {
      _handleError(
        StateError(
          'streamOutputResult completed without emitting an OutputResultEvent.',
        ),
        StackTrace.current,
      );
      return;
    }

    _foundation.close();
  }
}

typedef StreamObjectResult<T> = StreamOutputResult<T>;

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

  final context = StructuredOutputContext(
    responseId: result.responseId,
    responseTimestamp: result.responseTimestamp,
    responseModelId: result.responseModelId,
    finishReason: result.finishReason,
    rawFinishReason: result.rawFinishReason,
    usage: result.usage,
    providerMetadata: result.providerMetadata,
  );

  try {
    return _parseGenerateOutputResult(
      result: result,
      outputSpec: outputSpec,
      context: context,
    );
  } catch (error) {
    throw ModelError.fromUnknown(
      error,
      kind: ModelErrorKind.validation,
      details: _structuredOutputErrorDetails(
        text: result.text,
        context: context,
      ),
    );
  }
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
      final partialOutput = await _tryParsePartialOutput(
        outputSpec: outputSpec,
        text: accumulator.text,
      );

      if (partialOutput != null &&
          (!hasPartialOutput ||
              !_structuredOutputValueEquals(
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
  final context = _createStructuredOutputContext(result);
  yield OutputResultEvent<T>(
    await _parseGenerateOutputResult(
      result: result,
      outputSpec: outputSpec,
      context: context,
    ),
  );
}

T _identityObjectDecoder<T>(Map<String, Object?> json) {
  return json as T;
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
  return StreamOutputResult<T>._(
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

Object? _decodeJsonText(
  String text,
) {
  try {
    return jsonDecode(text);
  } on FormatException catch (error) {
    throw FormatException(
      'Could not parse structured output JSON: ${error.message}',
      text,
      error.offset,
    );
  }
}

JsonSchema _validateObjectSchema(JsonSchema schema) {
  final type = schema.toJson()['type'];
  if (type != 'object') {
    throw ArgumentError.value(
      schema,
      'schema',
      'ObjectOutputSpec requires an object-rooted schema.',
    );
  }

  return schema;
}

Map<String, Object?> _requireJsonObject(
  Object? json, {
  required String message,
}) {
  if (json is! Map) {
    throw FormatException(message);
  }

  final object = <String, Object?>{};
  for (final entry in json.entries) {
    final key = entry.key;
    if (key is! String) {
      throw FormatException(message);
    }

    object[key] = entry.value;
  }

  return Map<String, Object?>.unmodifiable(object);
}

List<T> _normalizeChoiceOptions<T extends String>(List<T> options) {
  if (options.isEmpty) {
    throw ArgumentError.value(
      options,
      'options',
      'ChoiceOutputSpec requires at least one option.',
    );
  }

  final seen = <String>{};
  final normalized = <T>[];
  for (final option in options) {
    if (option.isEmpty) {
      throw ArgumentError.value(
        option,
        'options',
        'ChoiceOutputSpec options must not be empty.',
      );
    }

    if (!seen.add(option)) {
      throw ArgumentError.value(
        option,
        'options',
        'ChoiceOutputSpec options must be unique.',
      );
    }

    normalized.add(option);
  }

  return List<T>.unmodifiable(normalized);
}

Map<String, Object?> _structuredOutputErrorDetails({
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
    if (context.usage != null) 'usage': _usageToJson(context.usage!),
    if (context.providerMetadata != null)
      'providerMetadata': context.providerMetadata!.toJsonMap(),
  };
}

StructuredOutputContext _createStructuredOutputContext(
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

Future<GenerateOutputResult<T>> _parseGenerateOutputResult<T>({
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
      details: _structuredOutputErrorDetails(
        text: result.text,
        context: context,
      ),
    );
  }
}

Future<Object?> _tryParsePartialOutput<T>({
  required OutputSpec<T> outputSpec,
  required String text,
}) async {
  try {
    return await outputSpec.parsePartial(text: text);
  } catch (_) {
    return null;
  }
}

Map<String, Object?>? _tryRequireJsonObject(Object? json) {
  try {
    return _requireJsonObject(
      json,
      message: 'Could not parse partial structured output object.',
    );
  } on FormatException {
    return null;
  }
}

Object? _freezeJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => List<Object?>.unmodifiable(
        value.map(_freezeJsonValue),
      ),
    Map() => Map<String, Object?>.unmodifiable(
        value.map(
          (key, nestedValue) => MapEntry(
            key as String,
            _freezeJsonValue(nestedValue),
          ),
        ),
      ),
    _ => value,
  };
}

bool _structuredOutputValueEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (!_structuredOutputValueEquals(left[index], right[index])) {
        return false;
      }
    }

    return true;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }

    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_structuredOutputValueEquals(entry.value, right[entry.key])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}

Map<String, Object?> _usageToJson(UsageStats usage) {
  return {
    if (usage.inputTokens != null) 'inputTokens': usage.inputTokens,
    if (usage.outputTokens != null) 'outputTokens': usage.outputTokens,
    if (usage.totalTokens != null) 'totalTokens': usage.totalTokens,
    if (usage.reasoningTokens != null) 'reasoningTokens': usage.reasoningTokens,
  };
}
