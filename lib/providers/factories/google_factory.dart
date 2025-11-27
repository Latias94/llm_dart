import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart';
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
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/',
        model: 'gemini-1.5-flash',
      );

  /// Transform unified config to Google-specific config
  GoogleConfig _transformConfig(LLMConfig config) {
    return GoogleConfig.fromLLMConfig(config);
  }
}
