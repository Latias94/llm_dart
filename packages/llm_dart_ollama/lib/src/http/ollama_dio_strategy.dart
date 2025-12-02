import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/ollama_config.dart';

/// Ollama-specific Dio strategy implementation for the sub-package.
class OllamaDioStrategy extends BaseProviderDioStrategy {
  @override
  String get providerName => 'Ollama';

  @override
  Map<String, String> buildHeaders(dynamic config) {
    final ollamaConfig = config as OllamaConfig;
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (ollamaConfig.apiKey != null && ollamaConfig.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${ollamaConfig.apiKey}';
    }

    return headers;
  }
}
