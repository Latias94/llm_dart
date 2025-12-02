import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/anthropic_config.dart';
import '../provider/anthropic_provider.dart';

/// Factory for creating Anthropic provider instances.
class AnthropicProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'anthropic';

  @override
  String get displayName => 'Anthropic';

  @override
  String get description =>
      'Anthropic Claude models including Claude 3.5 Sonnet and reasoning models';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      AnthropicProvider.baseCapabilities;

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<AnthropicConfig>(
      config,
      () => AnthropicConfig.fromLLMConfig(config),
      (anthropicConfig) => AnthropicProvider(anthropicConfig),
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://api.anthropic.com/v1/',
        model: 'claude-sonnet-4-20250514',
      );
}

/// Helper to register the Anthropic provider factory with the global registry.
void registerAnthropicProvider() {
  LLMProviderRegistry.registerOrReplace(AnthropicProviderFactory());
}
