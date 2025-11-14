import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
import 'base_factory.dart';
import 'package:llm_dart_phind/llm_dart_phind.dart';

/// Factory for creating Phind provider instances using native Phind interface
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
    return createProviderSafely<PhindConfig>(
      config,
      () => _transformConfig(config),
      (phindConfig) => PhindProvider(phindConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('phind');
  }

  /// Transform unified config to Phind-specific config
  PhindConfig _transformConfig(LLMConfig config) {
    return PhindConfig.fromLLMConfig(config);
  }
}
