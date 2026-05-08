import '../../../../core/config.dart';
import '../../../../providers/elevenlabs/config.dart';
import '../../config/legacy_elevenlabs_options.dart';
import '../../config/legacy_provider_options.dart';
import '../community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an ElevenLabs provider config.
ElevenLabsConfig createLegacyElevenLabsConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.elevenlabs,
  );
  final elevenLabsOptions = legacyElevenLabsOptions(options);

  return ElevenLabsConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    voiceId: elevenLabsOptions.voiceId,
    stability: elevenLabsOptions.stability,
    similarityBoost: elevenLabsOptions.similarityBoost,
    style: elevenLabsOptions.style,
    useSpeakerBoost: elevenLabsOptions.useSpeakerBoost,
  );
}
