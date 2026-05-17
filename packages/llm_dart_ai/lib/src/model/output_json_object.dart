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
