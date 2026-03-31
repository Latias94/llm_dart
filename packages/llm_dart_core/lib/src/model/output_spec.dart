import 'dart:async';
import 'dart:convert';

import '../common/call_options.dart';
import '../common/json_schema.dart';
import '../common/model_error.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import '../prompt/prompt_message.dart';
import '../tool/tool_definition.dart';
import 'language_model.dart';
import 'response_format.dart';

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

abstract interface class OutputSpec<T> {
  ResponseFormat? get responseFormat;

  FutureOr<T> parse({
    required String text,
    required StructuredOutputContext context,
  });
}

final class TextOutputSpec implements OutputSpec<String> {
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
}

final class JsonOutputSpec<T> implements OutputSpec<T> {
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
}

final class ObjectOutputSpec<T> implements OutputSpec<T> {
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
}

final class ArrayOutputSpec<T> implements OutputSpec<List<T>> {
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
}

final class ChoiceOutputSpec<T extends String> implements OutputSpec<T> {
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

Map<String, Object?> _usageToJson(UsageStats usage) {
  return {
    if (usage.inputTokens != null) 'inputTokens': usage.inputTokens,
    if (usage.outputTokens != null) 'outputTokens': usage.outputTokens,
    if (usage.totalTokens != null) 'totalTokens': usage.totalTokens,
    if (usage.reasoningTokens != null) 'reasoningTokens': usage.reasoningTokens,
  };
}
