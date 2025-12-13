import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config/ollama_config.dart';

/// Ollama-specific Dio strategy implementation for the sub-package.
class OllamaDioStrategy extends BaseProviderDioStrategy<OllamaConfig> {
  @override
  String get providerName => 'Ollama';

  @override
  Map<String, String> buildHeaders(OllamaConfig config) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (config.apiKey != null && config.apiKey!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.apiKey}';
    }

    return headers;
  }
}
