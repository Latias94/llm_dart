/// (Tier 3 / opt-in) Google Dio strategy used by `llm_dart_provider_utils`.
///
/// This library is intentionally not part of the recommended provider
/// entrypoints.
library;

import 'package:dio/dio.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'config.dart';

/// Google-specific Dio strategy implementation
///
/// Handles Google's unique authentication method using
/// query parameters instead of headers.
class GoogleDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Google';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    // Google uses query parameter authentication, so minimal headers.
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (!hasHeaderIgnoreCase(headers, 'user-agent')) {
      final googleConfig = config as GoogleConfig;
      headers['User-Agent'] =
          defaultUserAgentForProvider(googleConfig.providerOptionsName);
    }
    return headers;
  }

  @override
  List<DioEnhancer> getEnhancers(dynamic config) {
    final googleConfig = config as GoogleConfig;

    return [
      // Add query parameter authentication enhancer
      _GoogleAuthEnhancer(googleConfig.apiKey),
    ];
  }
}

/// Custom enhancer for Google's query parameter authentication
class _GoogleAuthEnhancer implements DioEnhancer {
  final String apiKey;

  _GoogleAuthEnhancer(this.apiKey);

  @override
  void enhance(Dio dio, dynamic config) {
    // Google authentication is handled at request time via query parameters
    // This enhancer could be extended to add default query parameters if needed
  }

  @override
  String get name => 'GoogleQueryAuth';
}
