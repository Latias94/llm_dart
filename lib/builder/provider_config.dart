import '../src/config/legacy_config_keys.dart';

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
      extension(LegacyExtensionKeys.frequencyPenalty, penalty);
  ProviderConfig presencePenalty(double penalty) =>
      extension(LegacyExtensionKeys.presencePenalty, penalty);
  ProviderConfig logitBias(Map<String, double> bias) =>
      extension(LegacyExtensionKeys.logitBias, bias);
  ProviderConfig seed(int seedValue) =>
      extension(LegacyExtensionKeys.seed, seedValue);
  ProviderConfig parallelToolCalls(bool enabled) =>
      extension(LegacyExtensionKeys.parallelToolCalls, enabled);
  ProviderConfig logprobs(bool enabled) =>
      extension(LegacyExtensionKeys.logprobs, enabled);
  ProviderConfig topLogprobs(int count) =>
      extension(LegacyExtensionKeys.topLogprobs, count);

  // Anthropic-specific configuration methods
  ProviderConfig reasoning(bool enable) =>
      extension(LegacyExtensionKeys.reasoning, enable);
  ProviderConfig thinkingBudgetTokens(int tokens) =>
      extension(LegacyExtensionKeys.thinkingBudgetTokens, tokens);
  ProviderConfig interleavedThinking(bool enable) =>
      extension(LegacyExtensionKeys.interleavedThinking, enable);
  ProviderConfig metadata(Map<String, dynamic> data) =>
      extension(LegacyExtensionKeys.metadata, data);

  // Ollama-specific configuration methods
  ProviderConfig numCtx(int contextLength) =>
      extension(LegacyExtensionKeys.numCtx, contextLength);
  ProviderConfig numGpu(int gpuLayers) =>
      extension(LegacyExtensionKeys.numGpu, gpuLayers);
  ProviderConfig numThread(int threads) =>
      extension(LegacyExtensionKeys.numThread, threads);
  ProviderConfig numa(bool enabled) =>
      extension(LegacyExtensionKeys.numa, enabled);
  ProviderConfig numBatch(int batchSize) =>
      extension(LegacyExtensionKeys.numBatch, batchSize);
  ProviderConfig keepAlive(String duration) =>
      extension(LegacyExtensionKeys.keepAlive, duration);
  ProviderConfig raw(bool enabled) =>
      extension(LegacyExtensionKeys.raw, enabled);
}
