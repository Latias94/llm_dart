import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/groq_config.dart';
import '../provider/groq_provider.dart';

/// Factory for creating Groq provider instances.
class GroqProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'groq';

  @override
  String get displayName => 'Groq';

  @override
  String get description => 'Groq AI models for ultra-fast inference';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<GroqConfig>(
      config,
      () => _transformConfig(config),
      (groqConfig) => GroqProvider(groqConfig),
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: groqDefaultBaseUrl,
        model: groqDefaultModel,
      );

  /// Transform unified config to Groq-specific config.
  GroqConfig _transformConfig(LLMConfig config) {
    return GroqConfig.fromLLMConfig(config);
  }
}

/// Helper to register the Groq provider factory with the global registry.
void registerGroqProvider() {
  LLMProviderRegistry.registerOrReplace(GroqProviderFactory());
}
