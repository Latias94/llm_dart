import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/provider_defaults.dart';
import '../groq/groq.dart';
import 'base_factory.dart';

/// Factory for creating Groq provider instances
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
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('groq');
  }

  /// Transform unified config to Groq-specific config
  GroqConfig _transformConfig(LLMConfig config) {
    return GroqConfig.fromLLMConfig(config);
  }
}
