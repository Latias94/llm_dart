import 'dart:async';
import 'dart:convert';

import '../common/partial_json.dart';
import '../common/replay_stream_channel.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'generate_text_result_accumulator.dart';
import 'language_model.dart';

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
  final ReplayStreamChannel<OutputStreamEvent<T>> _eventChannel =
      ReplayStreamChannel<OutputStreamEvent<T>>();
  final ReplayStreamChannel<Object?> _partialOutputChannel =
      ReplayStreamChannel<Object?>();
  final ReplayStreamChannel<Object?> _elementChannel =
      ReplayStreamChannel<Object?>();
  final Completer<GenerateOutputResult<T>> _resultCompleter =
      Completer<GenerateOutputResult<T>>();

  StreamOutputResult._(Stream<OutputStreamEvent<T>> source) {
    source.listen(
      _handleEvent,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: true,
    );
  }

  Stream<OutputStreamEvent<T>> get eventStream => _eventChannel.stream;

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

  Future<GenerateOutputResult<T>> get result => _resultCompleter.future;

  Future<T> get output => result.then((value) => value.output);

  void _handleEvent(OutputStreamEvent<T> event) {
    _eventChannel.add(event);

    switch (event) {
      case OutputTextStreamEvent<T>():
        break;
      case OutputPartialEvent<T>(:final partialOutput):
        _partialOutputChannel.add(partialOutput);
      case OutputElementEvent(:final element):
        _elementChannel.add(element);
      case OutputResultEvent<T>(:final result):
        if (!_resultCompleter.isCompleted) {
          _resultCompleter.complete(result);
        }
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(error, stackTrace);
    }

    _eventChannel.addError(error, stackTrace);
    _partialOutputChannel.addError(error, stackTrace);
    _elementChannel.addError(error, stackTrace);
  }

  void _handleDone() {
    if (!_resultCompleter.isCompleted) {
      _handleError(
        StateError(
          'streamOutputResult completed without emitting an OutputResultEvent.',
        ),
        StackTrace.current,
      );
      return;
    }

    _eventChannel.close();
    _partialOutputChannel.close();
    _elementChannel.close();
  }
}

Future<GenerateOutputResult<T>> generateOutput<T>({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) async {
  if (options.responseFormat != null) {
    throw ArgumentError(
      'generateOutput uses OutputSpec.responseFormat and does not allow GenerateTextOptions.responseFormat at the same time.',
    );
  }

  final result = await generateText(
    model: model,
    prompt: prompt,
    tools: tools,
    toolChoice: toolChoice,
    options: _withResponseFormat(
      options,
      outputSpec.responseFormat,
    ),
    callOptions: callOptions,
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
  required List<PromptMessage> prompt,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
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
    tools: tools,
    toolChoice: toolChoice,
    options: _withResponseFormat(
      options,
      outputSpec.responseFormat,
    ),
    callOptions: callOptions,
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

StreamOutputResult<T> streamOutputResult<T>({
  required LanguageModel model,
  required List<PromptMessage> prompt,
  required OutputSpec<T> outputSpec,
  List<FunctionToolDefinition> tools = const [],
  ToolChoice? toolChoice,
  GenerateTextOptions options = const GenerateTextOptions(),
  CallOptions callOptions = const CallOptions(),
}) {
  return StreamOutputResult<T>._(
    streamOutput(
      model: model,
      prompt: prompt,
      outputSpec: outputSpec,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      callOptions: callOptions,
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
