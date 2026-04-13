import '../../../../core/config.dart';
import '../../../../providers/elevenlabs/config.dart';
import '../../../config/legacy_config_extensions.dart';
import '../community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an ElevenLabs provider config.
ElevenLabsConfig createLegacyElevenLabsConfig(LLMConfig config) {
  return ElevenLabsConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    voiceId: config.getExtension<String>(LegacyExtensionKeys.voiceId),
    stability: config.getExtension<double>(LegacyExtensionKeys.stability),
    similarityBoost:
        config.getExtension<double>(LegacyExtensionKeys.similarityBoost),
    style: config.getExtension<double>(LegacyExtensionKeys.style),
    useSpeakerBoost:
        config.getExtension<bool>(LegacyExtensionKeys.useSpeakerBoost),
  );
}
