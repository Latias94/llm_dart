import 'dart:convert';

/// Best-effort stable JSON encoding for dedupe/cache keys.
///
/// - Sorts map keys recursively (by their string representation).
/// - Normalizes map keys to strings (to support non-string keys).
/// - Leaves scalars as-is.
///
/// Returns null when the value cannot be JSON-encoded.
String? tryStableJsonEncode(Object? value) {
  try {
    return jsonEncode(_normalizeJson(value));
  } catch (_) {
    return null;
  }
}

Object? _normalizeJson(Object? value) {
  if (value is List) {
    return value.map(_normalizeJson).toList(growable: false);
  }

  if (value is Map) {
    final entries = <MapEntry<String, Object?>>[];
    for (final e in value.entries) {
      entries.add(MapEntry(e.key.toString(), _normalizeJson(e.value)));
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return <String, Object?>{for (final e in entries) e.key: e.value};
  }

  return value;
}
