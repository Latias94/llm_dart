import 'package:llm_dart_core/llm_dart_core.dart';

/// Provider-specific configuration builder (legacy).
///
/// This type predates the provider-specific builder pattern based on
/// [LLMBuilder] (for example OpenAIBuilder, AnthropicBuilder,
/// OllamaBuilder). New code should prefer the `ai().openai(...)`,
/// `ai().anthropic(...)`, and related helpers instead of constructing
/// [ProviderConfig] directly.
///
/// It is kept for backwards compatibility and tests only and will be
/// removed in a future breaking release.
@Deprecated(
  'ProviderConfig is legacy. Use provider-specific builders like '
  'OpenAIBuilder / AnthropicBuilder / OllamaBuilder via '
  'ai().openai((o) => ...), ai().anthropic((a) => ...), etc. '
  'This type will be removed in a future breaking release.',
)
class ProviderConfig {
  final Map<String, dynamic> _config = {};

  /// OpenAI-specific configurations
  ProviderConfig openai() => this;

  /// Anthropic-specific configurations
  ProviderConfig anthropic() => this;

  /// Ollama-specific configurations
  ProviderConfig ollama() => this;

  /// Add extension directly
  ProviderConfig extension(String key, dynamic value) {
    _config[key] = value;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);

  // OpenAI-specific configuration methods
  ProviderConfig frequencyPenalty(double penalty) =>
      extension(LLMConfigKeys.frequencyPenalty, penalty);
  ProviderConfig presencePenalty(double penalty) =>
      extension(LLMConfigKeys.presencePenalty, penalty);
  ProviderConfig logitBias(Map<String, double> bias) =>
      extension(LLMConfigKeys.logitBias, bias);
  ProviderConfig seed(int seedValue) =>
      extension(LLMConfigKeys.seed, seedValue);
  ProviderConfig parallelToolCalls(bool enabled) =>
      extension(LLMConfigKeys.parallelToolCalls, enabled);
  ProviderConfig logprobs(bool enabled) =>
      extension(LLMConfigKeys.logprobs, enabled);
  ProviderConfig topLogprobs(int count) =>
      extension(LLMConfigKeys.topLogprobs, count);

  // Anthropic-specific configuration methods
  ProviderConfig reasoning(bool enable) =>
      extension(LLMConfigKeys.reasoning, enable);
  ProviderConfig thinkingBudgetTokens(int tokens) =>
      extension(LLMConfigKeys.thinkingBudgetTokens, tokens);
  ProviderConfig interleavedThinking(bool enable) =>
      extension(LLMConfigKeys.interleavedThinking, enable);
  ProviderConfig metadata(Map<String, dynamic> data) =>
      extension(LLMConfigKeys.metadata, data);

  // Ollama-specific configuration methods
  ProviderConfig numCtx(int contextLength) =>
      extension(LLMConfigKeys.numCtx, contextLength);
  ProviderConfig numGpu(int gpuLayers) =>
      extension(LLMConfigKeys.numGpu, gpuLayers);
  ProviderConfig numThread(int threads) =>
      extension(LLMConfigKeys.numThread, threads);
  ProviderConfig numa(bool enabled) => extension(LLMConfigKeys.numa, enabled);
  ProviderConfig numBatch(int batchSize) =>
      extension(LLMConfigKeys.numBatch, batchSize);
  ProviderConfig keepAlive(String duration) =>
      extension(LLMConfigKeys.keepAlive, duration);
  ProviderConfig raw(bool enabled) => extension(LLMConfigKeys.raw, enabled);
}
