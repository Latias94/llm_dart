import '../../core/capability.dart';
import '../../core/config.dart';
import '../../src/compatibility/providers/community_provider_config_adapters.dart';
import '../../src/provider_defaults.dart';
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
  Map<String, dynamic> getProviderDefaults() {
    return ProviderDefaults.getDefaults('elevenlabs');
  }

  /// Transform unified config to ElevenLabs-specific config
  ElevenLabsConfig _transformConfig(LLMConfig config) {
    return createLegacyElevenLabsConfig(config);
  }
}
