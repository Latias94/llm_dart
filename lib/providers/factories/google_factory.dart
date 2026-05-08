import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/google_compat_provider.dart';
import '../google/defaults.dart';
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
    return createProviderSafely<LLMConfig>(
      config,
      () => config,
      buildCompatGoogleProvider,
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    return {
      'baseUrl': GoogleDefaults.baseUrl,
      'model': GoogleDefaults.defaultModel,
    };
  }
}
