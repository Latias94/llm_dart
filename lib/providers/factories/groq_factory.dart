import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/openai_family_compat_groq.dart';
import '../groq/defaults.dart';
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
    return createProviderSafely<LLMConfig>(
      config,
      () => config,
      buildCompatGroqProvider,
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: GroqDefaults.baseUrl,
        model: GroqDefaults.defaultModel,
      );
}
