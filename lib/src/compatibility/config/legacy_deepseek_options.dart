import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';

final class LegacyDeepSeekOptions {
  final bool? logprobs;
  final int? topLogprobs;
  final double? frequencyPenalty;
  final double? presencePenalty;
  final Map<String, dynamic>? responseFormat;

  const LegacyDeepSeekOptions({
    required this.logprobs,
    required this.topLogprobs,
    required this.frequencyPenalty,
    required this.presencePenalty,
    required this.responseFormat,
  });
}

LegacyDeepSeekOptions legacyDeepSeekOptions(
  LegacyProviderOptionView options,
) {
  return LegacyDeepSeekOptions(
    logprobs: options.getWithFlatFallback<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.deepSeekTopLogprobs,
    ),
    frequencyPenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.deepSeekFrequencyPenalty,
    ),
    presencePenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.deepSeekPresencePenalty,
    ),
    responseFormat: options.getWithFlatFallback<Map<String, dynamic>>(
      LegacyExtensionKeys.deepSeekResponseFormat,
    ),
  );
}
