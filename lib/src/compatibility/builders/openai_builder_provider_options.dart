part of 'openai_builder.dart';

mixin _OpenAIBuilderProviderOptions {
  LegacyBuilderProviderOptionWriter get _providerOptions;

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0).
  OpenAIBuilder frequencyPenalty(double penalty) {
    _providerOptions.set(LegacyExtensionKeys.frequencyPenalty, penalty);
    return this as OpenAIBuilder;
  }

  /// Sets reasoning effort for models that support it.
  OpenAIBuilder reasoningEffort(ReasoningEffort effort) {
    _providerOptions.set(LegacyExtensionKeys.reasoningEffort, effort.value);
    return this as OpenAIBuilder;
  }

  /// Sets structured output schema for JSON responses.
  OpenAIBuilder jsonSchema(StructuredOutputFormat schema) {
    _providerOptions.set(LegacyExtensionKeys.jsonSchema, schema);
    return this as OpenAIBuilder;
  }

  /// Sets voice for text-to-speech requests.
  OpenAIBuilder voice(String voiceName) {
    _providerOptions.set(LegacyExtensionKeys.voice, voiceName);
    return this as OpenAIBuilder;
  }

  /// Sets embedding encoding format.
  OpenAIBuilder embeddingEncodingFormat(String format) {
    _providerOptions.set(
      LegacyExtensionKeys.embeddingEncodingFormat,
      format,
    );
    return this as OpenAIBuilder;
  }

  /// Sets embedding dimensions.
  OpenAIBuilder embeddingDimensions(int dimensions) {
    _providerOptions.set(
      LegacyExtensionKeys.embeddingDimensions,
      dimensions,
    );
    return this as OpenAIBuilder;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0).
  OpenAIBuilder presencePenalty(double penalty) {
    _providerOptions.set(LegacyExtensionKeys.presencePenalty, penalty);
    return this as OpenAIBuilder;
  }

  /// Sets logit bias for specific tokens.
  OpenAIBuilder logitBias(Map<String, double> bias) {
    _providerOptions.set(LegacyExtensionKeys.logitBias, bias);
    return this as OpenAIBuilder;
  }

  /// Sets seed for deterministic outputs.
  OpenAIBuilder seed(int seedValue) {
    _providerOptions.set(LegacyExtensionKeys.seed, seedValue);
    return this as OpenAIBuilder;
  }

  /// Enables or disables parallel tool calls.
  OpenAIBuilder parallelToolCalls(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.parallelToolCalls, enabled);
    return this as OpenAIBuilder;
  }

  /// Enables or disables log probabilities.
  OpenAIBuilder logprobs(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.logprobs, enabled);
    return this as OpenAIBuilder;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  OpenAIBuilder topLogprobs(int count) {
    _providerOptions.set(LegacyExtensionKeys.topLogprobs, count);
    return this as OpenAIBuilder;
  }

  /// Sets verbosity level for GPT-5 family models.
  OpenAIBuilder verbosity(Verbosity level) {
    _providerOptions.set(LegacyExtensionKeys.verbosity, level.value);
    return this as OpenAIBuilder;
  }
}
