import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';

/// DeepSeek-specific legacy builder DSL layered on top of [LLMBuilder].
class DeepSeekBuilder {
  final LLMBuilder _baseBuilder;

  DeepSeekBuilder(this._baseBuilder);

  /// Enables or disables token log probabilities.
  DeepSeekBuilder logprobs(bool enabled) {
    _setProviderOption(LegacyExtensionKeys.logprobs, enabled);
    return this;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  DeepSeekBuilder topLogprobs(int count) {
    _setProviderOption(LegacyExtensionKeys.deepSeekTopLogprobs, count);
    return this;
  }

  /// Sets frequency penalty for reducing repetition.
  DeepSeekBuilder frequencyPenalty(double penalty) {
    _setProviderOption(LegacyExtensionKeys.deepSeekFrequencyPenalty, penalty);
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity.
  DeepSeekBuilder presencePenalty(double penalty) {
    _setProviderOption(LegacyExtensionKeys.deepSeekPresencePenalty, penalty);
    return this;
  }

  /// Sets DeepSeek response format.
  DeepSeekBuilder responseFormat(Map<String, dynamic> format) {
    _setProviderOption(LegacyExtensionKeys.deepSeekResponseFormat, format);
    return this;
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  void _setProviderOption(String key, dynamic value) {
    setLegacyBuilderProviderOption(
      _baseBuilder,
      LegacyProviderOptionNamespaces.deepseek,
      key,
      value,
    );
  }
}
