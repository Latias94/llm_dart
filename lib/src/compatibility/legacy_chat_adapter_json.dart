part of 'legacy_chat_adapter.dart';

Object? _decodeToolResultOutput({
  required String encodedOutput,
  required String fallbackText,
}) {
  if (encodedOutput.trim().isNotEmpty) {
    return _decodeJsonValue(encodedOutput);
  }

  if (fallbackText.isNotEmpty) {
    return fallbackText;
  }

  return null;
}

Object? _decodeJsonValue(String encoded) {
  final normalized = encoded.trim();
  if (normalized.isEmpty) {
    return null;
  }

  try {
    return jsonDecode(normalized);
  } catch (_) {
    return normalized;
  }
}

String _encodeJsonValue(Object? value) {
  if (value == null) {
    return '{}';
  }

  if (value is String) {
    return value;
  }

  return jsonEncode(value);
}

Map<String, Object?> _normalizeMap(Map<String, dynamic> value) {
  return value.map(
    (key, entryValue) => MapEntry(
      key,
      _normalizeJsonValue(entryValue),
    ),
  );
}

Object? _normalizeJsonValue(Object? value) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value.map(_normalizeJsonValue).toList(growable: false),
    Map() => value.map(
        (key, nestedValue) => MapEntry(
          key as String,
          _normalizeJsonValue(nestedValue),
        ),
      ),
    _ => value.toString(),
  };
}
