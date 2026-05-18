import 'dart:typed_data';

Map<String, Object?> elevenLabsRequiredMap(
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

List<Object?> elevenLabsRequiredList(
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

String elevenLabsRequiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = elevenLabsOptionalString(value, path: path);
  if (normalized == null || normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? elevenLabsOptionalString(
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

Map<String, String> elevenLabsOptionalStringMap(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return const {};
  }

  if (value is! Map) {
    throw FormatException('Expected a string map at $path.');
  }

  return Map<String, String>.unmodifiable(
    value.map((key, mapValue) {
      if (key is! String || mapValue is! String) {
        throw FormatException('Expected string entries at $path.');
      }

      return MapEntry(key, mapValue);
    }),
  );
}

List<String> elevenLabsOptionalStringList(
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
    (index) => elevenLabsRequiredNonEmptyString(
      value[index],
      path: '$path[$index]',
    ),
    growable: false,
  );
}

Uint8List elevenLabsRequiredBytes(
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
    return Uint8List.fromList(
      List<int>.generate(
        value.length,
        (index) => elevenLabsRequiredByte(
          value[index],
          path: '$path[$index]',
        ),
        growable: false,
      ),
    );
  }

  throw StateError(
    'Expected $sourceName bytes at $path but received ${value.runtimeType}.',
  );
}

int elevenLabsRequiredByte(
  Object? value, {
  required String path,
}) {
  if (value is int) {
    return value;
  }

  throw StateError(
    'Expected ElevenLabs byte value at $path to be int, '
    'got ${value.runtimeType}.',
  );
}

String? elevenLabsLookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}
