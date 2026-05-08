import '../../../../core/config.dart';
import '../../../../providers/elevenlabs/config.dart';
import '../../config/legacy_config_extensions.dart';
import '../../config/legacy_provider_options.dart';
import '../community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an ElevenLabs provider config.
ElevenLabsConfig createLegacyElevenLabsConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.elevenlabs,
  );

  return ElevenLabsConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    voiceId: options.get<String>(LegacyExtensionKeys.voiceId),
    stability: options.get<double>(LegacyExtensionKeys.stability),
    similarityBoost: options.get<double>(
      LegacyExtensionKeys.similarityBoost,
    ),
    style: options.get<double>(LegacyExtensionKeys.style),
    useSpeakerBoost: options.get<bool>(
      LegacyExtensionKeys.useSpeakerBoost,
    ),
  );
}
