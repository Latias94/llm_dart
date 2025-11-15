import '../core/config.dart';

/// Provider-specific configuration builder
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
