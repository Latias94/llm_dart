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
      extension('frequencyPenalty', penalty);
  ProviderConfig presencePenalty(double penalty) =>
      extension('presencePenalty', penalty);
  ProviderConfig logitBias(Map<String, double> bias) =>
      extension('logitBias', bias);
  ProviderConfig seed(int seedValue) => extension('seed', seedValue);
  ProviderConfig parallelToolCalls(bool enabled) =>
      extension('parallelToolCalls', enabled);
  ProviderConfig logprobs(bool enabled) => extension('logprobs', enabled);
  ProviderConfig topLogprobs(int count) => extension('topLogprobs', count);

  // Anthropic-specific configuration methods
  ProviderConfig reasoning(bool enable) => extension('reasoning', enable);
  ProviderConfig thinkingBudgetTokens(int tokens) =>
      extension('thinkingBudgetTokens', tokens);
  ProviderConfig interleavedThinking(bool enable) =>
      extension('interleavedThinking', enable);
  ProviderConfig metadata(Map<String, dynamic> data) =>
      extension('metadata', data);

  // Ollama-specific configuration methods
  ProviderConfig numCtx(int contextLength) =>
      extension('numCtx', contextLength);
  ProviderConfig numGpu(int gpuLayers) => extension('numGpu', gpuLayers);
  ProviderConfig numThread(int threads) => extension('numThread', threads);
  ProviderConfig numa(bool enabled) => extension('numa', enabled);
  ProviderConfig numBatch(int batchSize) => extension('numBatch', batchSize);
  ProviderConfig keepAlive(String duration) => extension('keepAlive', duration);
  ProviderConfig raw(bool enabled) => extension('raw', enabled);
}
