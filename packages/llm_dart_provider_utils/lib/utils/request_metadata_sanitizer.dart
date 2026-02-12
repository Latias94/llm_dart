/// Utilities for sanitizing request bodies before exposing them as metadata.
///
/// This is intended for opt-in debugging/telemetry use cases (AI SDK parity).
/// Implementations should:
/// - avoid leaking secrets (when applicable),
/// - avoid emitting large/binary payloads (e.g. base64 files),
/// - keep output JSON-serializable.
library;

const int _defaultMaxDepth = 10;
const int _defaultMaxStringLength = 2048;
const int _defaultMaxListLength = 100;

/// Sanitize a JSON-like request body for request metadata emission.
///
/// The returned value is JSON-serializable (maps, lists, scalars) and applies:
/// - depth limiting,
/// - list truncation,
/// - long string truncation,
/// - best-effort omission of large binary-ish fields (by key heuristics).
Object? sanitizeRequestBodyForMetadata(
  Object? body, {
  int maxDepth = _defaultMaxDepth,
  int maxStringLength = _defaultMaxStringLength,
  int maxListLength = _defaultMaxListLength,
}) {
  return _sanitize(
    body,
    depth: 0,
    maxDepth: maxDepth,
    maxStringLength: maxStringLength,
    maxListLength: maxListLength,
    currentKey: null,
  );
}

Object? _sanitize(
  Object? value, {
  required int depth,
  required int maxDepth,
  required int maxStringLength,
  required int maxListLength,
  required String? currentKey,
}) {
  if (depth > maxDepth) {
    return '[omitted: max depth exceeded]';
  }

  if (value == null || value is num || value is bool) return value;

  if (value is String) {
    final key = currentKey ?? '';
    if (_isBinaryLikeKey(key) && value.length > 128) {
      return '[omitted: ${key.isEmpty ? 'binary-like' : key}, length=${value.length}]';
    }

    if (value.length <= maxStringLength) return value;

    final head = value.substring(0, maxStringLength);
    return '$head...[truncated, length=${value.length}]';
  }

  if (value is List) {
    final key = currentKey ?? '';
    if (_isBinaryLikeKey(key) && _looksLikeByteList(value)) {
      return '[omitted: ${key.isEmpty ? 'bytes' : key}, length=${value.length}]';
    }

    final out = <Object?>[];
    final limit = value.length > maxListLength ? maxListLength : value.length;
    for (var i = 0; i < limit; i++) {
      out.add(_sanitize(
        value[i],
        depth: depth + 1,
        maxDepth: maxDepth,
        maxStringLength: maxStringLength,
        maxListLength: maxListLength,
        currentKey: null,
      ));
    }
    if (value.length > maxListLength) {
      out.add('[... truncated, length=${value.length}]');
    }
    return out;
  }

  if (value is Map) {
    final out = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      out[key] = _sanitize(
        entry.value,
        depth: depth + 1,
        maxDepth: maxDepth,
        maxStringLength: maxStringLength,
        maxListLength: maxListLength,
        currentKey: key,
      );
    }
    return out;
  }

  // Fallback for non-JSON values.
  return value.toString();
}

bool _isBinaryLikeKey(String key) {
  if (key.isEmpty) return false;
  final k = key.toLowerCase();
  return k.contains('base64') ||
      k.contains('b64') ||
      k.contains('bytes') ||
      k.contains('data') ||
      k.contains('file') ||
      k.contains('image') ||
      k.contains('audio');
}

bool _looksLikeByteList(List value) {
  if (value.isEmpty) return false;
  if (value.length < 64) return false;
  for (final v in value) {
    if (v is! int) return false;
    if (v < 0 || v > 255) return false;
  }
  return true;
}
