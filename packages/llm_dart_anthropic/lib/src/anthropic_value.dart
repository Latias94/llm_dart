import 'dart:typed_data';

Map<String, Object?> anthropicRequiredMap(
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

List<Object?> anthropicRequiredList(
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

String anthropicRequiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = anthropicOptionalString(value, path: path);
  if (normalized == null || normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? anthropicOptionalString(
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

int anthropicRequiredInt(
  Object? value, {
  required String path,
}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Expected an int at $path.');
}

bool? anthropicOptionalBool(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

Uint8List anthropicRequiredBytes(
  Object? value, {
  required String path,
  required String sourceName,
}) {
  if (value is Uint8List) {
    return value;
  }

  if (value is List<int>) {
    return Uint8List.fromList(value);
  }

  if (value is List) {
    final bytes = <int>[];
    for (var index = 0; index < value.length; index += 1) {
      bytes.add(
        anthropicRequiredInt(
          value[index],
          path: '$path[$index]',
        ),
      );
    }
    return Uint8List.fromList(bytes);
  }

  throw StateError(
    'Expected $sourceName bytes at $path but received ${value.runtimeType}.',
  );
}

String? anthropicLookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}
