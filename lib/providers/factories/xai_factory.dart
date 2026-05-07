import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/openai_family_compat_xai.dart';
import '../../src/config/provider_defaults.dart';
import 'base_factory.dart';

/// Factory for creating XAI provider instances through the compatibility shell.
class XAIProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'xai';

  @override
  String get displayName => 'xAI (Grok)';

  @override
  String get description =>
      'xAI Grok models with search and reasoning capabilities';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.liveSearch,
        LLMCapability.embedding,
        LLMCapability.vision, // Grok Vision models
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<LLMConfig>(
      config,
      () => config,
      buildCompatXAIProvider,
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('xai');
  }
}
