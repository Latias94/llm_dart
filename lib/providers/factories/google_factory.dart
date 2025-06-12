import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
import '../google/google.dart';
import 'base_factory.dart';

/// Factory for creating Google (Gemini) provider instances
class GoogleProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'google';

  @override
  String get displayName => 'Google';

  @override
  String get description =>
      'Google Gemini models including Gemini 1.5 Flash and Pro';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.embedding,
        LLMCapability.reasoning,
        LLMCapability.vision,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<GoogleConfig>(
      config,
      () => _transformConfig(config),
      (googleConfig) => GoogleProvider(googleConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('google');
  }

  /// Transform unified config to Google-specific config
  GoogleConfig _transformConfig(LLMConfig config) {
    return GoogleConfig.fromLLMConfig(config);
  }
}
