import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart';
import 'base_factory.dart';

/// Factory for creating XAI provider instances using native XAI interface
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

  /// Transform unified config to XAI-specific config
  XAIConfig _transformConfig(LLMConfig config) {
    return XAIConfig.fromLLMConfig(config);
  }
}
