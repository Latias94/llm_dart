/// Sanitizers for response metadata (debug/observability).
///
/// This is best-effort and intentionally conservative:
/// - Header keys are normalized to lowercase for stability.
/// - Sensitive header values are redacted.
/// - Very large values are truncated to avoid memory/log noise.
library;

const _redactedValue = '[REDACTED]';

bool _isSensitiveHeaderKey(String keyLower) {
  switch (keyLower) {
    case 'authorization':
    case 'proxy-authorization':
    case 'cookie':
    case 'set-cookie':
    case 'x-api-key':
    case 'api-key':
    case 'x-goog-api-key':
    case 'x-aws-ec2-metadata-token':
      return true;
  }

  // Conservative substring matches.
  if (keyLower.contains('token')) return true;
  if (keyLower.contains('secret')) return true;
  if (keyLower.contains('session')) return true;

  return false;
}

String _truncate(String value, int maxLen) {
  if (value.length <= maxLen) return value;
  return value.substring(0, maxLen);
}

/// Sanitizes an HTTP response header map for use in [LLMResponseMetadataPart].
///
/// - Lowercases keys for deterministic access.
/// - Redacts sensitive keys.
/// - Truncates values to keep metadata bounded.
Map<String, String> sanitizeResponseHeadersForMetadata(
  Map<String, String> headers, {
  int maxHeaderCount = 100,
  int maxValueLength = 512,
}) {
  if (headers.isEmpty) return const <String, String>{};

  final out = <String, String>{};
  var count = 0;

  for (final entry in headers.entries) {
    if (count >= maxHeaderCount) break;

    final key = entry.key.trim();
    if (key.isEmpty) continue;

    final keyLower = key.toLowerCase();
    final value = entry.value;

    if (_isSensitiveHeaderKey(keyLower)) {
      out[keyLower] = _redactedValue;
      count++;
      continue;
    }

    final normalized = _truncate(value, maxValueLength);
    if (normalized.isEmpty) continue;

    out[keyLower] = normalized;
    count++;
  }

  return out.isEmpty ? const <String, String>{} : out;
}
