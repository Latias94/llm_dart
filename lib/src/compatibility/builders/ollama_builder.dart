import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../models/tool_models.dart';
import '../config/legacy_config_keys.dart';
import 'legacy_builder_provider_options.dart';

/// Ollama-specific LLM builder with provider-specific configuration methods.
///
/// This builder provides a layered configuration approach where Ollama-specific
/// parameters are handled separately from the generic LLMBuilder, keeping the
/// main builder clean and focused.
///
/// Use this for Ollama-specific parameters only. For common parameters like
/// apiKey, model, temperature, etc., continue using the base LLMBuilder
/// methods.
class OllamaBuilder {
  final LLMBuilder _baseBuilder;
  final LegacyBuilderProviderOptionWriter _providerOptions;

  OllamaBuilder(LLMBuilder baseBuilder)
      : _baseBuilder = baseBuilder,
        _providerOptions =
            LegacyBuilderProviderOptionWriter.ollama(baseBuilder);

  /// Sets the context window size (number of tokens).
  OllamaBuilder numCtx(int contextLength) {
    _providerOptions.set(LegacyExtensionKeys.numCtx, contextLength);
    return this;
  }

  /// Sets the number of GPU layers to use.
  OllamaBuilder numGpu(int gpuLayers) {
    _providerOptions.set(LegacyExtensionKeys.numGpu, gpuLayers);
    return this;
  }

  /// Sets the number of threads to use for computation.
  OllamaBuilder numThread(int threads) {
    _providerOptions.set(LegacyExtensionKeys.numThread, threads);
    return this;
  }

  /// Enables or disables NUMA optimization.
  OllamaBuilder numa(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.numa, enabled);
    return this;
  }

  /// Sets the batch size for processing.
  OllamaBuilder numBatch(int batchSize) {
    _providerOptions.set(LegacyExtensionKeys.numBatch, batchSize);
    return this;
  }

  /// Sets how long to keep the model loaded in memory.
  OllamaBuilder keepAlive(String duration) {
    _providerOptions.set(LegacyExtensionKeys.keepAlive, duration);
    return this;
  }

  /// Enables or disables raw mode.
  OllamaBuilder raw(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.raw, enabled);
    return this;
  }

  /// Sets structured output schema for Ollama chat requests.
  OllamaBuilder jsonSchema(StructuredOutputFormat schema) {
    _providerOptions.set(LegacyExtensionKeys.jsonSchema, schema);
    return this;
  }

  /// Configure for maximum performance (GPU-optimized).
  OllamaBuilder forMaxPerformance() {
    return numGpu(-1).numBatch(512).keepAlive('1h').numa(true);
  }

  /// Configure for memory efficiency.
  OllamaBuilder forMemoryEfficiency() {
    return numGpu(0).numCtx(1024).numBatch(128).keepAlive('5m');
  }

  /// Configure for balanced performance and memory usage.
  OllamaBuilder forBalanced() {
    return numGpu(20).numCtx(2048).numBatch(256).keepAlive('30m');
  }

  /// Configure for long conversations.
  OllamaBuilder forLongConversations() {
    return numCtx(8192).numBatch(512).keepAlive('2h').numGpu(-1);
  }

  /// Configure for development and testing.
  OllamaBuilder forDevelopment() {
    return numCtx(2048).numBatch(256).keepAlive('10m').numGpu(10);
  }

  /// Configure for production deployment.
  OllamaBuilder forProduction() {
    return numCtx(4096).numBatch(512).keepAlive('1h').numGpu(-1).numa(true);
  }

  /// Enables thinking for reasoning models.
  OllamaBuilder reasoning(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.reasoning, enabled);
    return this;
  }

  /// Configure for CPU-only inference.
  OllamaBuilder forCpuOnly({int? threads}) {
    final builder = numGpu(0).numBatch(64).keepAlive('15m');

    if (threads != null) {
      builder.numThread(threads);
    }

    return builder;
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with EmbeddingCapability.
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }
}
