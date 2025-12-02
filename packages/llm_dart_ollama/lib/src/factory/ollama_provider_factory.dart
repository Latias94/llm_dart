import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/ollama_config.dart';
import '../provider/ollama_provider.dart';

/// Factory for creating Ollama provider instances.
class OllamaProviderFactory extends LocalProviderFactory<ChatCapability> {
  @override
  String get providerId => 'ollama';

  @override
  String get displayName => 'Ollama';

  @override
  String get description =>
      'Ollama local LLM provider for self-hosted open source models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.completion,
        LLMCapability.embedding,
        LLMCapability.modelListing,
        LLMCapability.reasoning,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<OllamaConfig>(
      config,
      () => _transformConfig(config),
      (ollamaConfig) => OllamaProvider(ollamaConfig),
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'http://localhost:11434/',
        model: 'llama3.2',
      );

  /// Transform unified config to Ollama-specific config.
  OllamaConfig _transformConfig(LLMConfig config) {
    return OllamaConfig.fromLLMConfig(config);
  }
}

/// Helper to register the Ollama provider factory with the global registry.
void registerOllamaProvider() {
  LLMProviderRegistry.registerOrReplace(OllamaProviderFactory());
}
