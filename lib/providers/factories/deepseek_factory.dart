import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/openai_family_compat_deepseek.dart';
import '../../src/provider_defaults.dart';
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
    return createProviderSafely<LLMConfig>(
      config,
      () => config,
      buildCompatDeepSeekProvider,
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('deepseek');
  }
}
