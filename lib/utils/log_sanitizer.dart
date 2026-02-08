/// Logging sanitization utilities.
///
/// These helpers prevent accidental leakage of sensitive values (API keys,
/// bearer tokens, etc.) into application logs.
library;

class LogSanitizer {
  static const String _redacted = '***';

  static final Set<String> _sensitiveQueryKeys = {
    'key',
    'api_key',
    'apikey',
    'access_token',
    'token',
  };

  static final Set<String> _sensitiveHeaderKeys = {
    'authorization',
    'x-api-key',
    'api-key',
    'x-goog-api-key',
    'proxy-authorization',
  };

  /// Redact sensitive query parameter values from a URL or endpoint string.
  ///
  /// Works for both absolute URLs and relative endpoints.
  static String sanitizeEndpoint(String endpoint) {
    try {
      final uri = Uri.parse(endpoint);
      if (uri.query.isEmpty) return endpoint;

      final redactedQuery = <String, List<String>>{};
      for (final entry in uri.queryParametersAll.entries) {
        final keyLower = entry.key.toLowerCase();
        if (_sensitiveQueryKeys.contains(keyLower)) {
          redactedQuery[entry.key] = [_redacted];
        } else {
          redactedQuery[entry.key] = entry.value;
        }
      }

      final rebuilt = uri.replace(
        query: _buildQueryString(redactedQuery),
      );
      return rebuilt.toString();
    } catch (_) {
      // Best-effort fallback: avoid throwing from logging paths.
      return endpoint;
    }
  }

  /// Redact sensitive header values.
  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic> headers) {
    final out = <String, dynamic>{};
    for (final entry in headers.entries) {
      final keyLower = entry.key.toLowerCase();
      if (_sensitiveHeaderKeys.contains(keyLower)) {
        out[entry.key] = _redacted;
      } else {
        out[entry.key] = entry.value;
      }
    }
    return out;
  }

  static String _buildQueryString(Map<String, List<String>> params) {
    final parts = <String>[];
    for (final entry in params.entries) {
      final encodedKey = Uri.encodeQueryComponent(entry.key);
      for (final value in entry.value) {
        final encodedValue = Uri.encodeQueryComponent(value);
        parts.add('$encodedKey=$encodedValue');
      }
    }
    return parts.join('&');
  }
}
