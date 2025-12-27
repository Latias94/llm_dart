import 'package:dio/dio.dart';
import 'package:llm_dart_provider_utils/utils/dio_client_factory.dart';
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
    // Google uses query parameter authentication, so minimal headers
    return {'Content-Type': 'application/json'};
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
