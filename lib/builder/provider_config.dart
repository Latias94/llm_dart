import '../src/compatibility/config/legacy_config_keys.dart';
import '../src/compatibility/config/legacy_provider_options.dart';

/// Provider-specific configuration builder
class ProviderConfig {
  final Map<String, dynamic> _config = {};
  String? _activeOpenAIFamilyNamespace;

  /// OpenAI-specific configurations
  ProviderConfig openai() {
    _activeOpenAIFamilyNamespace = LegacyProviderOptionNamespaces.openai;
    return this;
  }

  /// OpenRouter-specific configurations
  ProviderConfig openRouter() {
    _activeOpenAIFamilyNamespace = LegacyProviderOptionNamespaces.openrouter;
    return this;
  }

  /// Anthropic-specific configurations
  ProviderConfig anthropic() {
    _activeOpenAIFamilyNamespace = null;
    return this;
  }

  /// Ollama-specific configurations
  ProviderConfig ollama() {
    _activeOpenAIFamilyNamespace = null;
    return this;
  }

  /// Add extension directly
  ProviderConfig extension(String key, dynamic value) {
    _config[key] = value;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);

  // OpenAI-specific configuration methods
  ProviderConfig frequencyPenalty(double penalty) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.frequencyPenalty, penalty);
  ProviderConfig presencePenalty(double penalty) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.presencePenalty, penalty);
  ProviderConfig logitBias(Map<String, double> bias) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.logitBias, bias);
  ProviderConfig seed(int seedValue) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.seed, seedValue);
  ProviderConfig parallelToolCalls(bool enabled) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.parallelToolCalls, enabled);
  ProviderConfig logprobs(bool enabled) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.logprobs, enabled);
  ProviderConfig topLogprobs(int count) =>
      _setOpenAIFamilyOption(LegacyExtensionKeys.topLogprobs, count);

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
