import '../llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// DeepSeek-specific LLM builder with provider-specific configuration methods.
///
/// This builder configures DeepSeek-specific parameters (logprobs,
/// top_logprobs, frequency/presence penalties, JSON response format)
/// on top of the generic [LLMBuilder] configuration.
///
/// Use this for DeepSeek-specific parameters only. For common parameters like
/// [LLMBuilder.apiKey], [LLMBuilder.model], [LLMBuilder.temperature], etc.,
/// continue using the base [LLMBuilder] methods.
class DeepSeekBuilder {
  final LLMBuilder _baseBuilder;

  DeepSeekBuilder(this._baseBuilder);

  /// Enables or disables log probabilities for DeepSeek.
  ///
  /// When enabled, the provider returns token-level log probabilities.
  /// This value is consumed by [DeepSeekConfig.fromLLMConfig] via
  /// [LLMConfigKeys.logprobs] (and the legacy 'logprobs' key).
  DeepSeekBuilder logprobs(bool enabled) {
    _baseBuilder.extension(LLMConfigKeys.logprobs, enabled);
    return this;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  ///
  /// This configures `top_logprobs` in the DeepSeek API via the
  /// [LLMConfigKeys.topLogprobs] extension key.
  DeepSeekBuilder topLogprobs(int count) {
    _baseBuilder.extension(LLMConfigKeys.topLogprobs, count);
    return this;
  }

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0).
  ///
  /// This controls `frequency_penalty` in the DeepSeek API and is read
  /// from [LLMConfigKeys.frequencyPenalty] by [DeepSeekConfig.fromLLMConfig].
  DeepSeekBuilder frequencyPenalty(double penalty) {
    // Delegate to the base builder so shared sampling configuration
    // stays consistent across providers.
    _baseBuilder.frequencyPenalty(penalty);
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0).
  ///
  /// This controls `presence_penalty` in the DeepSeek API and is read
  /// from [LLMConfigKeys.presencePenalty] by [DeepSeekConfig.fromLLMConfig].
  DeepSeekBuilder presencePenalty(double penalty) {
    // Delegate to the base builder so shared sampling configuration
    // stays consistent across providers.
    _baseBuilder.presencePenalty(penalty);
    return this;
  }

  /// Configures JSON response format for DeepSeek.
  ///
  /// This writes a raw JSON schema (or other response format configuration)
  /// into [LLMConfigKeys.responseFormat], which [DeepSeekConfig.fromLLMConfig]
  /// forwards to the DeepSeek API as `response_format`.
  DeepSeekBuilder responseFormat(Map<String, dynamic> format) {
    _baseBuilder.extension(LLMConfigKeys.responseFormat, format);
    return this;
  }

  // ========== Build methods ==========

  /// Builds and returns a configured DeepSeek chat provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with [ModelListingCapability] for DeepSeek.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }
}
