Map<String, Object?> requiredOllamaJsonMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected a JSON object at $path.');
}

List<Object?> requiredOllamaJsonList(
  Object? value, {
  required String path,
}) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  throw FormatException('Expected a list at $path.');
}

String requiredOllamaNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = optionalOllamaString(value, path: path);
  if (normalized == null || normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? optionalOllamaString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string at $path.');
}

List<String> optionalOllamaStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return const [];
  }

  if (value is! List) {
    throw FormatException('Expected a string list at $path.');
  }

  return List<String>.generate(
    value.length,
    (index) => requiredOllamaNonEmptyString(
      value[index],
      path: '$path[$index]',
    ),
    growable: false,
  );
}

int? optionalOllamaInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Expected an int at $path.');
}

DateTime? optionalOllamaDateTime(
  Object? value, {
  required String path,
}) {
  final text = optionalOllamaString(value, path: path);
  if (text == null) {
    return null;
  }

  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    throw FormatException('Expected an ISO-8601 datetime at $path.');
  }
  return parsed;
}
