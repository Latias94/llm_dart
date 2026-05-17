import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

Object? decodeStructuredOutputJsonText(
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

JsonSchema validateStructuredOutputObjectSchema(JsonSchema schema) {
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

Map<String, Object?> requireStructuredOutputJsonObject(
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

Map<String, Object?>? tryRequireStructuredOutputJsonObject(Object? json) {
  try {
    return requireStructuredOutputJsonObject(
      json,
      message: 'Could not parse partial structured output object.',
    );
  } on FormatException {
    return null;
  }
}

Object? freezeStructuredOutputJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => List<Object?>.unmodifiable(
        value.map(freezeStructuredOutputJsonValue),
      ),
    Map() => Map<String, Object?>.unmodifiable(
        value.map(
          (key, nestedValue) => MapEntry(
            key as String,
            freezeStructuredOutputJsonValue(nestedValue),
          ),
        ),
      ),
    _ => value,
  };
}

bool structuredOutputValueEquals(Object? left, Object? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (!structuredOutputValueEquals(left[index], right[index])) {
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
          !structuredOutputValueEquals(entry.value, right[entry.key])) {
        return false;
      }
    }

    return true;
  }

  return left == right;
}

List<T> normalizeStructuredOutputChoiceOptions<T extends String>(
  List<T> options,
) {
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

Map<String, Object?> structuredOutputUsageToJson(UsageStats usage) {
  return {
    if (usage.inputTokens != null) 'inputTokens': usage.inputTokens,
    if (usage.outputTokens != null) 'outputTokens': usage.outputTokens,
    if (usage.totalTokens != null) 'totalTokens': usage.totalTokens,
    if (usage.reasoningTokens != null) 'reasoningTokens': usage.reasoningTokens,
  };
}
