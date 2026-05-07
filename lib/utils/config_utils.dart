/// Utility class for compatibility HTTP header construction.
///
/// Most request-body and message conversion logic now lives in provider-owned
/// compatibility adapters. This helper remains only for the small set of
/// legacy Dio strategies that still share header shaping.
class ConfigUtils {
  /// Extract common HTTP headers from config
  static Map<String, String> buildHeaders({
    required String apiKey,
    required String authHeaderName,
    String? authPrefix,
    Map<String, String>? additionalHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      authHeaderName: authPrefix != null ? '$authPrefix $apiKey' : apiKey,
    };

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Build OpenAI-compatible headers
  static Map<String, String> buildOpenAIHeaders(String apiKey) {
    return buildHeaders(
      apiKey: apiKey,
      authHeaderName: 'Authorization',
      authPrefix: 'Bearer',
    );
  }

  /// Build Anthropic-compatible headers
  static Map<String, String> buildAnthropicHeaders(String apiKey) {
    return buildHeaders(
      apiKey: apiKey,
      authHeaderName: 'x-api-key',
      additionalHeaders: {
        'anthropic-version': '2023-06-01',
      },
    );
  }
}
