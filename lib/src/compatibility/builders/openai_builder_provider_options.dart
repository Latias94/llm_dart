part of 'openai_builder.dart';

mixin _OpenAIBuilderProviderOptions {
  LLMBuilder get _baseBuilder;

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0).
  OpenAIBuilder frequencyPenalty(double penalty) {
    _setOpenAIProviderOption(LegacyExtensionKeys.frequencyPenalty, penalty);
    return this as OpenAIBuilder;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0).
  OpenAIBuilder presencePenalty(double penalty) {
    _setOpenAIProviderOption(LegacyExtensionKeys.presencePenalty, penalty);
    return this as OpenAIBuilder;
  }

  /// Sets logit bias for specific tokens.
  OpenAIBuilder logitBias(Map<String, double> bias) {
    _setOpenAIProviderOption(LegacyExtensionKeys.logitBias, bias);
    return this as OpenAIBuilder;
  }

  /// Sets seed for deterministic outputs.
  OpenAIBuilder seed(int seedValue) {
    _setOpenAIProviderOption(LegacyExtensionKeys.seed, seedValue);
    return this as OpenAIBuilder;
  }

  /// Enables or disables parallel tool calls.
  OpenAIBuilder parallelToolCalls(bool enabled) {
    _setOpenAIProviderOption(LegacyExtensionKeys.parallelToolCalls, enabled);
    return this as OpenAIBuilder;
  }

  /// Enables or disables log probabilities.
  OpenAIBuilder logprobs(bool enabled) {
    _setOpenAIProviderOption(LegacyExtensionKeys.logprobs, enabled);
    return this as OpenAIBuilder;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  OpenAIBuilder topLogprobs(int count) {
    _setOpenAIProviderOption(LegacyExtensionKeys.topLogprobs, count);
    return this as OpenAIBuilder;
  }

  /// Sets verbosity level for GPT-5 family models.
  OpenAIBuilder verbosity(Verbosity level) {
    _setOpenAIProviderOption(LegacyExtensionKeys.verbosity, level.value);
    return this as OpenAIBuilder;
  }

  void _setOpenAIProviderOption(String key, dynamic value) {
    final providerOptions = setLegacyProviderOption(
      _baseBuilder.currentConfig,
      LegacyProviderOptionNamespaces.openai,
      key,
      value,
    );

    _baseBuilder.extension(legacyProviderOptionsBagKey, providerOptions);
  }
}
