import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyElevenLabsOptions {
  final String? voiceId;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  const LegacyElevenLabsOptions({
    required this.voiceId,
    required this.stability,
    required this.similarityBoost,
    required this.style,
    required this.useSpeakerBoost,
  });
}

LegacyElevenLabsOptions legacyElevenLabsOptions(
  LegacyProviderOptionView options,
) {
  return LegacyElevenLabsOptions(
    voiceId: options.getWithFlatFallback<String>(LegacyExtensionKeys.voiceId),
    stability:
        options.getWithFlatFallback<double>(LegacyExtensionKeys.stability),
    similarityBoost: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.similarityBoost,
    ),
    style: options.getWithFlatFallback<double>(LegacyExtensionKeys.style),
    useSpeakerBoost: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.useSpeakerBoost,
    ),
  );
}
