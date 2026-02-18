import 'dart:convert';

/// A minimal parse result container aligned with the upstream AI SDK shape.
class ParseResult<T> {
  final bool success;
  final T? value;
  final Object? error;

  const ParseResult._({
    required this.success,
    this.value,
    this.error,
  });

  factory ParseResult.success(T value) =>
      ParseResult._(success: true, value: value);

  factory ParseResult.failure(Object error) =>
      ParseResult._(success: false, error: error);
}

/// Safely parses a JSON string and optionally decodes it into [T].
///
/// This mirrors the upstream `safeParseJSON(...)` behavior at a high level,
/// but keeps the API Dart-friendly.
ParseResult<T> safeParseJson<T>({
  required String text,
  required T Function(Object? json) decode,
}) {
  try {
    final json = jsonDecode(text);
    try {
      return ParseResult.success(decode(json));
    } catch (e) {
      return ParseResult.failure(e);
    }
  } catch (e) {
    return ParseResult.failure(e);
  }
}
