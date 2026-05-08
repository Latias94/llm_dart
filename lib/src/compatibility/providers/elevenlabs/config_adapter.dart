import '../../../../core/config.dart';
import '../../../../providers/elevenlabs/config.dart';
import '../../config/legacy_config_extensions.dart';
import '../../config/legacy_provider_options.dart';
import '../community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an ElevenLabs provider config.
ElevenLabsConfig createLegacyElevenLabsConfig(LLMConfig config) {
  return ElevenLabsConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    voiceId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.elevenlabs,
      LegacyExtensionKeys.voiceId,
    ),
    stability: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.elevenlabs,
      LegacyExtensionKeys.stability,
    ),
    similarityBoost: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.elevenlabs,
      LegacyExtensionKeys.similarityBoost,
    ),
    style: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.elevenlabs,
      LegacyExtensionKeys.style,
    ),
    useSpeakerBoost: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.elevenlabs,
      LegacyExtensionKeys.useSpeakerBoost,
    ),
  );
}
