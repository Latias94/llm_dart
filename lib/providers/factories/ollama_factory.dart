import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
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
      () => _transformConfig(config),
      (ollamaConfig) => OllamaProvider(ollamaConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('ollama');
  }

  /// Transform unified config to Ollama-specific config
  OllamaConfig _transformConfig(LLMConfig config) {
    return OllamaConfig(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey, // Optional for Ollama
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      // Ollama-specific extensions using safe access
      jsonSchema: getExtension(config, 'jsonSchema'),
      originalConfig: config,
    );
  }
}
