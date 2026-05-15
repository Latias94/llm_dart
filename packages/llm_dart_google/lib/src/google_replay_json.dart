import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_shared.dart';

Map<String, Object?> normalizeGoogleReplayJsonObject(
  Object? value, {
  required String path,
}) {
  final normalized = normalizeJsonValue(value);
  if (normalized is Map<String, Object?>) {
    return normalized;
  }

  if (normalized is Map) {
    return Map<String, Object?>.from(normalized);
  }

  throw FormatException('Expected $path to be a JSON object.');
}

Map<String, Object?> requireGoogleReplayObject(
  Object? value, {
  required String path,
}) {
  final object = asMap(value);
  if (object == null) {
    throw FormatException('Expected $path to be an object.');
  }

  return object;
}

String requireGoogleReplayNonEmptyString(
  Object? value, {
  required String path,
}) {
  final stringValue = asString(value);
  if (stringValue == null || stringValue.isEmpty) {
    throw FormatException('Expected $path to be a non-empty string.');
  }

  return stringValue;
}

String? optionalGoogleReplayNonEmptyString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Expected $path to be a string.');
  }

  return value.isEmpty ? null : value;
}

String requireGoogleReplayNonEmptyValue(
  String value, {
  required String name,
}) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }

  return value;
}

String? normalizeGoogleOptionalDisplayName(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return value;
}
