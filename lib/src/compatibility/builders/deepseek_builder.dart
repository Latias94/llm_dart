import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../config/legacy_config_keys.dart';
import 'legacy_builder_provider_options.dart';

/// DeepSeek-specific legacy builder DSL layered on top of [LLMBuilder].
class DeepSeekBuilder {
  final LLMBuilder _baseBuilder;
  final LegacyBuilderProviderOptionWriter _providerOptions;

  DeepSeekBuilder(LLMBuilder baseBuilder)
      : _baseBuilder = baseBuilder,
        _providerOptions =
            LegacyBuilderProviderOptionWriter.deepSeek(baseBuilder);

  /// Enables or disables token log probabilities.
  DeepSeekBuilder logprobs(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.logprobs, enabled);
    return this;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  DeepSeekBuilder topLogprobs(int count) {
    _providerOptions.set(LegacyExtensionKeys.deepSeekTopLogprobs, count);
    return this;
  }

  /// Sets frequency penalty for reducing repetition.
  DeepSeekBuilder frequencyPenalty(double penalty) {
    _providerOptions.set(
      LegacyExtensionKeys.deepSeekFrequencyPenalty,
      penalty,
    );
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity.
  DeepSeekBuilder presencePenalty(double penalty) {
    _providerOptions.set(
      LegacyExtensionKeys.deepSeekPresencePenalty,
      penalty,
    );
    return this;
  }

  /// Sets DeepSeek response format.
  DeepSeekBuilder responseFormat(Map<String, dynamic> format) {
    _providerOptions.set(LegacyExtensionKeys.deepSeekResponseFormat, format);
    return this;
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }
}
