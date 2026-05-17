import 'package:llm_dart_provider/llm_dart_provider.dart';

Map<String, Object?> anthropicReplayNormalizeObject(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  throw FormatException('Expected a JSON object at $path.');
}

Map<String, Object?> anthropicReplayRequiredObject(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  throw FormatException('Expected an object at $path.');
}

List<Object?> anthropicReplayRequiredList(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value, path: path);
  if (normalized is List<Object?>) {
    return normalized;
  }

  if (normalized is List) {
    return List<Object?>.from(normalized);
  }

  throw FormatException('Expected a list at $path.');
}

String anthropicReplayRequiredString(
  Object? value, {
  required String path,
}) {
  final normalized = anthropicReplayOptionalString(value, path: path);
  if (normalized == null) {
    throw FormatException('Expected a string at $path.');
  }

  return normalized;
}

String anthropicReplayRequiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = anthropicReplayRequiredString(value, path: path);
  if (normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? anthropicReplayOptionalString(
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

int anthropicReplayRequiredInt(
  Object? value, {
  required String path,
}) {
  final normalized = anthropicReplayNullableInt(value, path: path);
  if (normalized == null) {
    throw FormatException('Expected an int at $path.');
  }

  return normalized;
}

int? anthropicReplayNullableInt(
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

bool anthropicReplayRequiredBool(
  Object? value, {
  required String path,
}) {
  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

List<String>? anthropicReplayNullableStringList(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  final list = anthropicReplayRequiredList(value, path: path);
  return [
    for (var index = 0; index < list.length; index++)
      anthropicReplayRequiredString(
        list[index],
        path: '$path[$index]',
      ),
  ];
}
