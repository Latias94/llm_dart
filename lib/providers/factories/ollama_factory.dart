import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/ollama/config_adapter.dart';
import '../ollama/ollama.dart';
import 'base_factory.dart';

/// Factory for creating Ollama provider instances
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
        LLMCapability.embedding,
        LLMCapability.modelListing,
        LLMCapability.reasoning,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<OllamaConfig>(
      config,
      () => createLegacyOllamaConfig(config),
      (ollamaConfig) => OllamaProvider(ollamaConfig),
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: OllamaDefaults.baseUrl,
        model: OllamaDefaults.defaultModel,
      );
}
