/// Utilities for redacting sensitive values from logs.
///
/// Provider clients typically put secrets (API keys, bearer tokens) in headers.
/// Logging raw headers is a foot-gun, especially in shared CI logs.
class LogRedactor {
  static const String redacted = '[REDACTED]';

  /// Redact sensitive headers (case-insensitive key matching).
  ///
  /// This keeps structure for debugging while preventing secret leakage.
  static Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return const {};

    final out = <String, dynamic>{};
    for (final entry in headers.entries) {
      final key = entry.key;
      final lower = key.toLowerCase();

      // Common auth headers across providers.
      final isSensitive = lower == 'authorization' ||
          lower == 'proxy-authorization' ||
          lower == 'x-api-key' ||
          lower == 'xi-api-key' ||
          lower == 'api-key' ||
          lower == 'apikey' ||
          lower == 'x-goog-api-key' ||
          lower.endsWith('-api-key') ||
          lower.contains('token');

      out[key] = isSensitive ? redacted : entry.value;
    }

    return out;
  }
}
