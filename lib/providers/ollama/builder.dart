import '../../builder/llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Ollama-specific LLM builder with provider-specific configuration methods
///
/// This builder provides a layered configuration approach where Ollama-specific
/// parameters are handled separately from the generic LLMBuilder, keeping the
/// main builder clean and focused.
///
/// Use this for Ollama-specific parameters only. For common parameters like
/// apiKey, model, temperature, etc., continue using the base LLMBuilder methods.
class OllamaBuilder {
  final LLMBuilder _baseBuilder;

  OllamaBuilder(this._baseBuilder);

  // ========== Ollama-specific configuration methods ==========

  /// Sets the context window size (number of tokens)
  ///
  /// Controls the size of the context window used to generate the next token.
  /// Larger values use more memory but can handle longer conversations.
  ///
  /// - Default: Model-specific (usually 2048-4096)
  /// - Range: Depends on model, typically 512-32768+
  /// - Higher values: Better long-term memory, more GPU memory usage
  /// - Lower values: Less memory usage, shorter context retention
  OllamaBuilder numCtx(int contextLength) {
    _baseBuilder.extension(LLMConfigKeys.numCtx, contextLength);
    return this;
  }

  /// Sets the number of GPU layers to use
  ///
  /// Controls how many layers of the model are loaded onto the GPU.
  /// More layers on GPU means faster inference but higher GPU memory usage.
  ///
  /// - 0: CPU only (slowest, lowest memory)
  /// - -1: Load all layers on GPU (fastest, highest memory)
  /// - Positive number: Load specified number of layers on GPU
  OllamaBuilder numGpu(int gpuLayers) {
    _baseBuilder.extension(LLMConfigKeys.numGpu, gpuLayers);
    return this;
  }

  /// Sets the number of threads to use for computation
  ///
  /// Controls the number of CPU threads used for inference.
  /// More threads can improve performance on multi-core systems.
  ///
  /// - Default: Number of CPU cores
  /// - Range: 1 to number of available CPU cores
  /// - Higher values: Better CPU utilization, more CPU usage
  /// - Lower values: Less CPU usage, potentially slower inference
  OllamaBuilder numThread(int threads) {
    _baseBuilder.extension(LLMConfigKeys.numThread, threads);
    return this;
  }

  /// Enables or disables NUMA (Non-Uniform Memory Access) optimization
  ///
  /// NUMA optimization can improve performance on multi-socket systems
  /// by optimizing memory access patterns.
  ///
  /// - true: Enable NUMA optimization (recommended for multi-socket systems)
  /// - false: Disable NUMA optimization (default)
  OllamaBuilder numa(bool enabled) {
    _baseBuilder.extension(LLMConfigKeys.numa, enabled);
    return this;
  }

  /// Sets the batch size for processing
  ///
  /// Controls the number of tokens processed in parallel during inference.
  /// Larger batch sizes can improve throughput but use more memory.
  ///
  /// - Default: 512
  /// - Range: 1-2048 (depends on available memory)
  /// - Higher values: Better throughput, more memory usage
  /// - Lower values: Less memory usage, potentially lower throughput
  OllamaBuilder numBatch(int batchSize) {
    _baseBuilder.extension(LLMConfigKeys.numBatch, batchSize);
    return this;
  }

  /// Sets how long to keep the model loaded in memory
  ///
  /// Controls how long the model stays loaded after the last request.
  /// Keeping models loaded reduces startup time for subsequent requests.
  ///
  /// - "5m": Keep loaded for 5 minutes
  /// - "1h": Keep loaded for 1 hour
  /// - "0": Unload immediately after use
  /// - "-1": Keep loaded indefinitely
  ///
  /// Examples: "30s", "5m", "1h", "24h"
  OllamaBuilder keepAlive(String duration) {
    _baseBuilder.extension(LLMConfigKeys.keepAlive, duration);
    return this;
  }

  /// Enables or disables raw mode
  ///
  /// When enabled, no formatting will be applied to the prompt.
  /// The model will receive the exact prompt without any template processing.
  ///
  /// - true: Raw mode (no prompt formatting)
  /// - false: Normal mode with prompt templates (default)
  OllamaBuilder raw(bool enabled) {
    _baseBuilder.extension(LLMConfigKeys.raw, enabled);
    return this;
  }

  // ========== Convenience methods for common configurations ==========

  /// Configure for maximum performance (GPU-optimized)
  ///
  /// Optimizes settings for maximum inference speed using GPU acceleration.
  /// Requires sufficient GPU memory.
  OllamaBuilder forMaxPerformance() {
    return numGpu(-1) // Use all GPU layers
        .numBatch(512) // Large batch size
        .keepAlive("1h") // Keep loaded for 1 hour
        .numa(true); // Enable NUMA if available
  }

  /// Configure for memory efficiency
  ///
  /// Optimizes settings to minimize memory usage, suitable for
  /// resource-constrained environments.
  OllamaBuilder forMemoryEfficiency() {
    return numGpu(0) // CPU only
        .numCtx(1024) // Smaller context window
        .numBatch(128) // Smaller batch size
        .keepAlive("5m"); // Shorter keep-alive
  }

  /// Configure for balanced performance and memory usage
  ///
  /// Provides a good balance between performance and resource usage.
  /// Suitable for most general-purpose applications.
  OllamaBuilder forBalanced() {
    return numGpu(20) // Partial GPU usage
        .numCtx(2048) // Moderate context window
        .numBatch(256) // Moderate batch size
        .keepAlive("30m"); // Moderate keep-alive
  }

  /// Configure for long conversations
  ///
  /// Optimizes settings for handling long conversations with
  /// extended context retention.
  OllamaBuilder forLongConversations() {
    return numCtx(8192) // Large context window
        .numBatch(512) // Large batch size for efficiency
        .keepAlive("2h") // Keep loaded longer
        .numGpu(-1); // Use GPU for speed
  }

  /// Configure for development and testing
  ///
  /// Settings optimized for development work with quick model loading
  /// and reasonable resource usage.
  OllamaBuilder forDevelopment() {
    return numCtx(2048)
        .numBatch(256)
        .keepAlive("10m") // Quick unloading for testing
        .numGpu(10); // Moderate GPU usage
  }

  /// Configure for production deployment
  ///
  /// Optimized settings for production environments with
  /// stability and efficiency focus.
  OllamaBuilder forProduction() {
    return numCtx(4096)
        .numBatch(512)
        .keepAlive("1h") // Balance between performance and memory
        .numGpu(-1) // Use all available GPU
        .numa(true); // Enable NUMA optimization
  }

  /// Enables thinking for reasoning models
  ///
  /// When enabled, the model will think before responding.
  /// Only works with models that support reasoning/thinking.
  ///
  /// - true: Enable reasoning mode
  /// - false: Disable reasoning mode (default)
  OllamaBuilder reasoning(bool enabled) {
    // Delegate to the base builder so that reasoning behaviour is
    // configured via the canonical extension key and shared helpers.
    _baseBuilder.reasoning(enabled);
    return this;
  }

  /// Configure for CPU-only inference
  ///
  /// Optimized for systems without GPU or when GPU usage
  /// should be avoided.
  OllamaBuilder forCpuOnly({int? threads}) {
    final builder = numGpu(0)
        .numBatch(64) // Smaller batch for CPU
        .keepAlive("15m");

    if (threads != null) {
      builder.numThread(threads);
    }

    return builder;
  }

  // ========== Build methods ==========

  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with EmbeddingCapability
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  /// Builds a provider with ModelListingCapability
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }
}
