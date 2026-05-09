import '../../../../providers/openai/config.dart';
import '../../config/legacy_config_keys.dart';

/// Reads OpenAI-family options from the explicit compatibility config fields.
T? getOpenAIFamilyProviderOption<T>({
  required OpenAIConfig config,
  required String providerId,
  required String key,
}) {
  final value = switch (key) {
    LegacyExtensionKeys.frequencyPenalty => config.frequencyPenalty,
    LegacyExtensionKeys.presencePenalty => config.presencePenalty,
    LegacyExtensionKeys.logitBias => config.logitBias,
    LegacyExtensionKeys.seed => config.seed,
    LegacyExtensionKeys.parallelToolCalls => config.parallelToolCalls,
    LegacyExtensionKeys.logprobs => config.logprobs,
    LegacyExtensionKeys.topLogprobs => config.topLogprobs,
    LegacyExtensionKeys.verbosity => config.verbosity,
    _ => null,
  };

  return value as T?;
}
