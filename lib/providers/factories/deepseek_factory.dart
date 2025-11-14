import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
import '../../core/provider_defaults.dart';

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
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('deepseek');
  }

  /// Transform unified config to DeepSeek-specific config
  DeepSeekConfig _transformConfig(LLMConfig config) {
    return DeepSeekConfig.fromLLMConfig(config);
  }
}
