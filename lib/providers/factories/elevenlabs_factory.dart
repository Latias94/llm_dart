import '../../core/capability.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';
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
      'ElevenLabs voice synthesis and speech recognition services';

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
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('elevenlabs');
  }

  /// Transform unified config to ElevenLabs-specific config
  ElevenLabsConfig _transformConfig(LLMConfig config) {
    return ElevenLabsConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      timeout: config.timeout,
      // ElevenLabs-specific extensions using base class method
      voiceId: getExtension<String>(config, 'voiceId'),
      stability: getExtension<double>(config, 'stability'),
      similarityBoost: getExtension<double>(config, 'similarityBoost'),
      style: getExtension<double>(config, 'style'),
      useSpeakerBoost: getExtension<bool>(config, 'useSpeakerBoost'),
      originalConfig: config,
    );
  }
}
