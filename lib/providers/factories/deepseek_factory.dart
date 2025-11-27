import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

import 'base_factory.dart';

/// Factory for creating DeepSeek provider instances
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

  /// Transform unified config to DeepSeek-specific config
  DeepSeekConfig _transformConfig(LLMConfig config) {
    return DeepSeekConfig.fromLLMConfig(config);
  }
}
