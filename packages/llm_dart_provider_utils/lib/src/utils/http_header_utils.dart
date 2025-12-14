import 'package:dio/dio.dart';

/// HTTP header utilities shared across providers.
///
/// This helper centralizes common header-building patterns such as
/// OpenAI-style `Authorization` headers and Anthropic-style `x-api-key`
/// headers so that providers and legacy adapters do not duplicate logic.
class HttpHeaderUtils {
  /// Build generic headers with optional prefix and additional entries.
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

  /// Build OpenAI-compatible headers.
  static Map<String, String> buildOpenAIHeaders(String apiKey) {
    return buildHeaders(
      apiKey: apiKey,
      authHeaderName: 'Authorization',
      authPrefix: 'Bearer',
    );
  }

  /// Build Anthropic-compatible headers.
  static Map<String, String> buildAnthropicHeaders(String apiKey) {
    return buildHeaders(
      apiKey: apiKey,
      authHeaderName: 'x-api-key',
      additionalHeaders: const {
        'anthropic-version': '2023-06-01',
      },
    );
  }

  /// Merge Dio default headers with per-call overrides.
  ///
  /// Dio stores default headers as `Map<String, dynamic>`. This helper
  /// normalizes them into a `Map<String, String>` and applies optional
  /// [additional] overrides.
  static Map<String, String> mergeDioHeaders(
    Dio dio, [
    Map<String, String>? additional,
  ]) {
    final result = <String, String>{};

    dio.options.headers.forEach((key, value) {
      if (value == null) return;
      if (value is String) {
        result[key] = value;
      } else {
        result[key] = value.toString();
      }
    });

    if (additional != null && additional.isNotEmpty) {
      result.addAll(additional);
    }

    return result;
  }
}
