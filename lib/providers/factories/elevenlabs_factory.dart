import 'package:llm_dart_core/llm_dart_core.dart';
import '../elevenlabs/elevenlabs.dart';
import 'base_factory.dart';

/// Factory for creating ElevenLabs provider instances
///
/// Note: ElevenLabs is primarily a TTS/STT service and does not support chat functionality.
/// This factory creates ElevenLabsProvider instances for voice synthesis and recognition.
///
/// Since ElevenLabsProvider doesn't implement ChatCapability, we use a wrapper approach
/// or return the provider directly for audio-specific use cases.
class ElevenLabsProviderFactory extends BaseProviderFactory<ChatCapability> {
  @override
  String get providerId => 'elevenlabs';

  @override
  String get displayName => 'ElevenLabs';

  @override
  String get description =>
      'ElevenLabs text-to-speech and speech recognition services';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<ElevenLabsConfig>(
      config,
      () => _transformConfig(config),
      (elevenLabsConfig) {
        final provider = ElevenLabsProvider(elevenLabsConfig);
        // Return the provider - it should implement the necessary interfaces
        return provider as ChatCapability;
      },
    );
  }

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: 'https://api.elevenlabs.io/v1/',
        model: 'eleven_multilingual_v2',
      );

  /// Transform unified config to ElevenLabs-specific config
  ElevenLabsConfig _transformConfig(LLMConfig config) {
    return ElevenLabsConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      timeout: config.timeout,
      // ElevenLabs-specific extensions using base class method
      voiceId: getExtension<String>(config, LLMConfigKeys.voiceId),
      stability: getExtension<double>(config, LLMConfigKeys.stability),
      similarityBoost:
          getExtension<double>(config, LLMConfigKeys.similarityBoost),
      style: getExtension<double>(config, LLMConfigKeys.style),
      useSpeakerBoost:
          getExtension<bool>(config, LLMConfigKeys.useSpeakerBoost),
      originalConfig: config,
    );
  }
}
