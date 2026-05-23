/// Compatibility bridge for OpenAI-family `ProviderOptionsBag` values.
///
/// New provider and runtime code should prefer typed option classes such as
/// `OpenAIGenerateTextOptions`, `OpenAIImageOptions`, and provider-specific
/// profile options. This library remains exported so existing
/// `ProviderOptionsBag` callers can encode/decode compatibility payloads.
library;

import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../embedding/openai_embedding_options.dart';
import '../image/openai_image_options.dart';
import '../image/openai_image_types.dart';
import '../language/openai_generate_text_options.dart';
import '../language/openai_response_format.dart';
import '../speech/openai_speech_options.dart';
import '../transcription/openai_transcription_options.dart';
import 'deepseek_options.dart';
import 'openrouter_options.dart';
import 'xai_options.dart';

part 'openai_provider_options_bag_generate_text.dart';
part 'openai_provider_options_bag_non_text.dart';

const openAIProviderOptionsNamespace = 'openai';
const deepSeekProviderOptionsNamespace = 'deepseek';
const openRouterProviderOptionsNamespace = 'openrouter';
const xaiProviderOptionsNamespace = 'xai';

OpenAILogProbs? _parseOpenAILogProbs(
  Object? value, {
  required String path,
}) {
  return switch (value) {
    null => null,
    bool() when value == true => const OpenAILogProbs.enabled(),
    int() => OpenAILogProbs.top(value),
    Map() => _parseOpenAILogProbsObject(value, path: path),
    _ => throw FormatException('Expected bool, int, or JSON object at $path.'),
  };
}

Object? _encodeOpenAILogProbs(OpenAILogProbs? value) {
  if (value == null) {
    return null;
  }

  return value.topLogProbs == null
      ? true
      : {
          'top_logprobs': value.topLogProbs,
        };
}

OpenAILogProbs _parseOpenAILogProbsObject(
  Map value, {
  required String path,
}) {
  final map = asJsonMap(value, path: path);
  final enabled = _optionalBool(map, 'enabled', path: '$path.enabled');
  final topLogProbs = _optionalInt(
    map,
    'topLogProbs',
    snakeKey: 'top_logprobs',
    path: '$path.topLogProbs',
  );

  if (topLogProbs != null) {
    return OpenAILogProbs.top(topLogProbs);
  }

  if (enabled == false) {
    throw FormatException('Expected enabled=true at $path.enabled.');
  }

  return const OpenAILogProbs.enabled();
}

OpenAIJsonSchemaResponseFormat? _parseOpenAIJsonSchemaResponseFormat(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final map = asJsonMap(value, path: path);
  final jsonSchema = map['json_schema'] is Map
      ? asJsonMap(map['json_schema'], path: '$path.json_schema')
      : map;

  return OpenAIJsonSchemaResponseFormat(
    name: asJsonString(jsonSchema['name'], path: '$path.name'),
    description: asNullableJsonString(
      jsonSchema['description'],
      path: '$path.description',
    ),
    schema: jsonSchema['schema'] == null
        ? null
        : asJsonMap(jsonSchema['schema'], path: '$path.schema'),
    strict: asNullableJsonBool(jsonSchema['strict'], path: '$path.strict'),
  );
}

OpenRouterSearchOptions? _parseOpenRouterSearchOptions(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final mode = value is String
      ? value
      : asJsonString(asJsonMap(value, path: path)['mode'], path: '$path.mode');

  return switch (mode) {
    'onlineModel' ||
    'online_model' ||
    'online' =>
      const OpenRouterSearchOptions.onlineModel(),
    _ => throw FormatException('Unsupported OpenRouter search mode at $path.'),
  };
}

XAILiveSearchOptions? _parseXAILiveSearchOptions(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final map = asJsonMap(value, path: path);
  return XAILiveSearchOptions(
    mode: _optionalEnumByWireValue(
          map,
          'mode',
          XAISearchMode.values,
          (value) => value.wireValue,
          path: '$path.mode',
        ) ??
        XAISearchMode.auto,
    returnCitations: _optionalBool(
          map,
          'returnCitations',
          snakeKey: 'return_citations',
          path: '$path.returnCitations',
        ) ??
        true,
    fromDate: _optionalDate(
      map,
      'fromDate',
      snakeKey: 'from_date',
      path: '$path.fromDate',
    ),
    toDate: _optionalDate(
      map,
      'toDate',
      snakeKey: 'to_date',
      path: '$path.toDate',
    ),
    maxSearchResults: _optionalInt(
      map,
      'maxSearchResults',
      snakeKey: 'max_search_results',
      path: '$path.maxSearchResults',
    ),
  );
}

DateTime? _optionalDate(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return DateTime.parse(asJsonString(raw, path: path));
}

T? _optionalEnumByWireValue<T extends Object>(
  JsonMap values,
  String key,
  List<T> allowed,
  String Function(T value) wireValue, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  final text = asJsonString(raw, path: path);
  for (final value in allowed) {
    if (wireValue(value) == text) {
      return value;
    }
  }

  throw FormatException('Unsupported enum value "$text" at $path.');
}

List<T>? _optionalEnumListByWireValue<T extends Object>(
  JsonMap values,
  String key,
  List<T> allowed,
  String Function(T value) wireValue, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return asJsonList(raw, path: path)
      .asMap()
      .entries
      .map(
        (entry) => _enumByWireValue(
          asJsonString(entry.value, path: '$path[${entry.key}]'),
          allowed,
          wireValue,
          path: '$path[${entry.key}]',
        ),
      )
      .toList(growable: false);
}

T _enumByWireValue<T extends Object>(
  String text,
  List<T> allowed,
  String Function(T value) wireValue, {
  required String path,
}) {
  for (final value in allowed) {
    if (wireValue(value) == text) {
      return value;
    }
  }

  throw FormatException('Unsupported enum value "$text" at $path.');
}

String? _optionalString(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  return asNullableJsonString(raw, path: path);
}

bool? _optionalBool(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  return asNullableJsonBool(raw, path: path);
}

int? _optionalInt(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  return asNullableJsonInt(raw, path: path);
}

double? _optionalDouble(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  if (raw is num) {
    return raw.toDouble();
  }

  throw FormatException('Expected number at $path.');
}

JsonMap? _optionalMap(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return asJsonMap(raw, path: path);
}

List<String>? _optionalStringList(
  JsonMap values,
  String key, {
  String? snakeKey,
  required String path,
}) {
  final raw = _lookup(values, key, snakeKey: snakeKey);
  if (raw == null) {
    return null;
  }

  return asJsonList(raw, path: path)
      .asMap()
      .entries
      .map((entry) => asJsonString(entry.value, path: '$path[${entry.key}]'))
      .toList(growable: false);
}

Object? _lookup(
  JsonMap values,
  String key, {
  String? snakeKey,
}) {
  if (values.containsKey(key)) {
    return values[key];
  }

  if (snakeKey != null && values.containsKey(snakeKey)) {
    return values[snakeKey];
  }

  return null;
}

String _path(String namespace, String key) =>
    '\$.providerOptions.$namespace.$key';
