import 'dart:typed_data';

Map<String, Object?> openAIRequiredMap(
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

Map<String, Object?>? openAIOptionalMap(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return openAIRequiredMap(value, path: path);
}

List<Object?> openAIRequiredList(
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

List<Object?>? openAIOptionalList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return openAIRequiredList(value, path: path);
}

String openAIRequiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final string = openAIOptionalString(value, path: path);
  if (string == null || string.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }
  return string;
}

String? openAIOptionalString(
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

int openAIRequiredInt(
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

int? openAIOptionalInt(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return openAIRequiredInt(value, path: path);
}

double openAIRequiredDouble(
  Object? value, {
  required String path,
}) {
  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected a number at $path.');
}

double? openAIOptionalDouble(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return openAIRequiredDouble(value, path: path);
}

bool openAIRequiredBool(
  Object? value, {
  required String path,
}) {
  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

bool? openAIOptionalBool(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return openAIRequiredBool(value, path: path);
}

Map<String, String>? openAIOptionalStringMap(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final map = openAIRequiredMap(value, path: path);
  return map.map((key, value) {
    if (value is! String) {
      throw FormatException('Expected a string value at $path.$key.');
    }
    return MapEntry(key, value);
  });
}

List<String>? openAIOptionalStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final list = openAIRequiredList(value, path: path);
  return List<String>.generate(
    list.length,
    (index) {
      final item = list[index];
      if (item is! String) {
        throw FormatException('Expected a string at $path[$index].');
      }
      return item;
    },
    growable: false,
  );
}

DateTime openAIRequiredEpochSecondsDateTime(
  Object? value, {
  required String path,
}) {
  return DateTime.fromMillisecondsSinceEpoch(
    openAIRequiredInt(value, path: path) * 1000,
    isUtc: true,
  );
}

DateTime? openAIOptionalEpochSecondsDateTime(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }
  return openAIRequiredEpochSecondsDateTime(value, path: path);
}

Uint8List openAIRequiredBytes(
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
      bytes.add(openAIRequiredInt(value[index], path: '$path[$index]'));
    }
    return Uint8List.fromList(bytes);
  }

  throw StateError(
    'Expected $sourceName bytes at $path but received ${value.runtimeType}.',
  );
}

String? openAILookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}
