import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';

/// Provider-specific configuration builder for legacy compatibility providers.
class ProviderConfig {
  final Map<String, dynamic> _config = {};
  String? _activeOpenAIFamilyNamespace;

  /// Select OpenAI-specific option namespacing.
  ProviderConfig openai() {
    _activeOpenAIFamilyNamespace = LegacyProviderOptionNamespaces.openai;
    return this;
  }

  /// Select OpenRouter-specific option namespacing.
  ProviderConfig openRouter() {
    _activeOpenAIFamilyNamespace = LegacyProviderOptionNamespaces.openrouter;
    return this;
  }

  /// Select Anthropic-specific option namespacing.
  ProviderConfig anthropic() {
    _activeOpenAIFamilyNamespace = null;
    return this;
  }

  /// Select Ollama-specific option namespacing.
  ProviderConfig ollama() {
    _activeOpenAIFamilyNamespace = null;
    return this;
  }

  /// Add extension directly.
  ProviderConfig extension(String key, dynamic value) {
    _config[key] = value;
    return this;
  }

  /// Get the configuration map.
  Map<String, dynamic> build() => Map.from(_config);

  /// Sets OpenAI-compatible frequency penalty.
  ProviderConfig frequencyPenalty(double penalty) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.frequencyPenalty, penalty);

  /// Sets OpenAI-compatible presence penalty.
  ProviderConfig presencePenalty(double penalty) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.presencePenalty, penalty);

  /// Sets OpenAI-compatible logit bias.
  ProviderConfig logitBias(Map<String, double> bias) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.logitBias, bias);

  /// Sets OpenAI-compatible seed.
  ProviderConfig seed(int seedValue) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.seed, seedValue);

  /// Enables OpenAI-compatible parallel tool calls.
  ProviderConfig parallelToolCalls(bool enabled) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.parallelToolCalls, enabled);

  /// Enables OpenAI-compatible token log probabilities.
  ProviderConfig logprobs(bool enabled) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.logprobs, enabled);

  /// Sets OpenAI-compatible top log probability count.
  ProviderConfig topLogprobs(int count) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.topLogprobs, count);

  /// Enables Anthropic-style reasoning.
  ProviderConfig reasoning(bool enable) =>
      extension(LegacyExtensionKeys.reasoning, enable);

  /// Sets Anthropic-style thinking budget tokens.
  ProviderConfig thinkingBudgetTokens(int tokens) =>
      extension(LegacyExtensionKeys.thinkingBudgetTokens, tokens);

  /// Enables Anthropic interleaved thinking.
  ProviderConfig interleavedThinking(bool enable) =>
      extension(LegacyExtensionKeys.interleavedThinking, enable);

  /// Sets provider metadata.
  ProviderConfig metadata(Map<String, dynamic> data) =>
      extension(LegacyExtensionKeys.metadata, data);

  /// Sets Ollama context length.
  ProviderConfig numCtx(int contextLength) =>
      extension(LegacyExtensionKeys.numCtx, contextLength);

  /// Sets Ollama GPU layer count.
  ProviderConfig numGpu(int gpuLayers) =>
      extension(LegacyExtensionKeys.numGpu, gpuLayers);

  /// Sets Ollama thread count.
  ProviderConfig numThread(int threads) =>
      extension(LegacyExtensionKeys.numThread, threads);

  /// Enables Ollama NUMA mode.
  ProviderConfig numa(bool enabled) =>
      extension(LegacyExtensionKeys.numa, enabled);

  /// Sets Ollama batch size.
  ProviderConfig numBatch(int batchSize) =>
      extension(LegacyExtensionKeys.numBatch, batchSize);

  /// Sets Ollama keep-alive duration.
  ProviderConfig keepAlive(String duration) =>
      extension(LegacyExtensionKeys.keepAlive, duration);

  /// Enables Ollama raw mode.
  ProviderConfig raw(bool enabled) =>
      extension(LegacyExtensionKeys.raw, enabled);

  ProviderConfig _setOpenAIFamilyOption(String key, dynamic value) {
    final namespace =
        _activeOpenAIFamilyNamespace ?? LegacyProviderOptionNamespaces.openai;
    final providerOptions = Map<String, dynamic>.from(
      _config[legacyProviderOptionsBagKey] as Map<String, dynamic>? ?? const {},
    );
    final namespaceOptions = Map<String, dynamic>.from(
      providerOptions[namespace] as Map<String, dynamic>? ?? const {},
    );

    namespaceOptions[key] = value;
    providerOptions[namespace] = namespaceOptions;
    _config[legacyProviderOptionsBagKey] = providerOptions;
    return this;
  }
}
