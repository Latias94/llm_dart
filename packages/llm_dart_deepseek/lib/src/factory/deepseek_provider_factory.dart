import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/deepseek_config.dart';
import '../provider/deepseek_provider.dart';

/// Factory for creating DeepSeek provider instances.
class DeepSeekProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'deepseek';

  @override
  String get displayName => 'DeepSeek';

  @override
  String get description =>
      'DeepSeek AI models including DeepSeek Chat and reasoning models';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.completion,
        LLMCapability.modelListing,
        LLMCapability.reasoning,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<DeepSeekConfig>(
      config,
      () => _transformConfig(config),
      (deepseekConfig) => DeepSeekProvider(deepseekConfig),
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://api.deepseek.com/v1/',
        model: 'deepseek-chat',
      );

  /// Transform unified config to DeepSeek-specific config.
  DeepSeekConfig _transformConfig(LLMConfig config) {
    return DeepSeekConfig.fromLLMConfig(config);
  }
}

/// Helper to register the DeepSeek provider factory with the global registry.
void registerDeepSeekProvider() {
  LLMProviderRegistry.registerOrReplace(DeepSeekProviderFactory());
}
