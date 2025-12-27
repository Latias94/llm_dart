import 'package:llm_dart_provider_utils/utils/dio_client_factory.dart';
import 'config.dart';

/// Ollama-specific Dio strategy implementation
///
/// Handles Ollama's optional API key authentication.
class OllamaDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Ollama';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final ollamaConfig = config as OllamaConfig;
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    // Add authorization header only if API key is provided
    if (ollamaConfig.apiKey != null && ollamaConfig.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${ollamaConfig.apiKey}';
    }

    return headers;
  }
}
