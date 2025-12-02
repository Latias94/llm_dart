import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/xai_config.dart';
import '../provider/xai_provider.dart';

/// Factory for creating XAI provider instances using native XAI interface.
class XAIProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'xai';

  @override
  String get displayName => 'xAI (Grok)';

  @override
  String get description =>
      'xAI Grok models with search and reasoning capabilities';

  @override
  Set<LLMCapability> get supportedCapabilities => XAIProvider.baseCapabilities;

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<XAIConfig>(
      config,
      () => _transformConfig(config),
      (xaiConfig) => XAIProvider(xaiConfig),
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://api.x.ai/v1/',
        model: 'grok-3',
      );

  /// Transform unified config to XAI-specific config.
  XAIConfig _transformConfig(LLMConfig config) {
    return XAIConfig.fromLLMConfig(config);
  }
}

/// Helper to register the XAI provider factory with the global registry.
void registerXAIProvider() {
  LLMProviderRegistry.registerOrReplace(XAIProviderFactory());
}
