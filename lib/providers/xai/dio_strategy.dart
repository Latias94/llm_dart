import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'config.dart';

/// xAI-specific Dio strategy implementation
///
/// Handles xAI's Bearer token authentication.
class XAIDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'xAI';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final xaiConfig = config as XAIConfig;
    return _buildXAIHeaders(xaiConfig.apiKey);
  }

  /// Build xAI-specific HTTP headers
  static Map<String, String> _buildXAIHeaders(String apiKey) {
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }
}
