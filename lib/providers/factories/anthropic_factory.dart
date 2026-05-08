import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/anthropic_compat_shell.dart';
import '../anthropic/defaults.dart';
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
    return createProviderSafely<LLMConfig>(
      config,
      () => config,
      buildCompatAnthropicProvider,
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: AnthropicDefaults.baseUrl,
        model: AnthropicDefaults.defaultModel,
      );
}
