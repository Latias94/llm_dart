import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/openai_family_compat_phind.dart';
import '../../src/config/provider_defaults.dart';
import 'base_factory.dart';

/// Factory for creating Phind provider instances through the compatibility
/// shell, preferring the modern OpenAI-family bridge when the request is safe.
class PhindProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'phind';

  @override
  String get displayName => 'Phind';

  @override
  String get description =>
      'Phind AI models specialized for coding assistance and development tasks';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<LLMConfig>(
      config,
      () => config,
      buildCompatPhindProvider,
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('phind');
  }
}
