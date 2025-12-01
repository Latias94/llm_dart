import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/elevenlabs_config.dart';
import '../provider/elevenlabs_provider.dart';

/// Factory for creating ElevenLabs provider instances.
///
/// Note: ElevenLabs is primarily a TTS/STT service and does not support chat
/// functionality. This factory creates [ElevenLabsProvider] instances for
/// voice synthesis and recognition.
class ElevenLabsProviderFactory
    extends AudioProviderFactory<ElevenLabsProvider> {
  @override
  String get providerId => 'elevenlabs';

  @override
  String get displayName => 'ElevenLabs';

  @override
  String get description =>
      'ElevenLabs text-to-speech and speech recognition services';

  @override
  ElevenLabsProvider create(LLMConfig config) {
    return createProviderSafely<ElevenLabsConfig>(
      config,
      () => _transformConfig(config),
      (elevenLabsConfig) => ElevenLabsProvider(elevenLabsConfig),
    );
  }

  @override
  Set<LLMCapability> get supportedCapabilities =>
      ElevenLabsProvider.baseCapabilities;

  @override
  LLMConfig getDefaultConfig() => const LLMConfig(
        baseUrl: elevenLabsDefaultBaseUrl,
        model: elevenLabsDefaultTTSModel,
      );

  /// Transform unified config to ElevenLabs-specific config.
  ElevenLabsConfig _transformConfig(LLMConfig config) {
    return ElevenLabsConfig.fromLLMConfig(config);
  }
}

/// Helper to register the ElevenLabs provider factory with the global registry.
void registerElevenLabsProvider() {
  LLMProviderRegistry.registerOrReplace(ElevenLabsProviderFactory());
}
