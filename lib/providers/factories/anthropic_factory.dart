import '../../core/chat_provider.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
import '../anthropic/anthropic.dart';
import 'base_factory.dart';

/// Factory for creating Anthropic provider instances
class AnthropicProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'anthropic';

  @override
  String get displayName => 'Anthropic';

  @override
  String get description =>
      'Anthropic Claude models including Claude 3.5 Sonnet and reasoning models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<AnthropicConfig>(
      config,
      () => AnthropicConfig.fromLLMConfig(config),
      (anthropicConfig) => AnthropicProvider(anthropicConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('anthropic');
  }
}
