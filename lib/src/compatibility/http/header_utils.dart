/// Utility class for compatibility HTTP header construction.
///
/// Most request-body and message conversion logic now lives in provider-owned
/// compatibility adapters. This helper remains only for the small set of
/// legacy Dio strategies that still share header shaping.
class CompatHeaderUtils {
  /// Extract common HTTP headers from config.
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

  /// Build standard Bearer-token authorization headers.
  static Map<String, String> buildBearerAuthHeaders(
    String apiKey, {
    Map<String, String>? additionalHeaders,
  }) {
    return buildHeaders(
      apiKey: apiKey,
      authHeaderName: 'Authorization',
      authPrefix: 'Bearer',
      additionalHeaders: additionalHeaders,
    );
  }

  /// Build API-key authorization headers.
  static Map<String, String> buildApiKeyHeaders({
    required String apiKey,
    required String authHeaderName,
    Map<String, String>? additionalHeaders,
  }) {
    return buildHeaders(
      apiKey: apiKey,
      authHeaderName: authHeaderName,
      additionalHeaders: additionalHeaders,
    );
  }
}
