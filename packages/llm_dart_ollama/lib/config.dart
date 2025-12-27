import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/models/tool_models.dart';

/// Ollama provider configuration
///
/// This class contains all configuration options for the Ollama providers.
/// It's extracted from the main provider to improve modularity and reusability.
class OllamaConfig {
  final String baseUrl;
  final String? apiKey;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final StructuredOutputFormat? jsonSchema;

  // Ollama-specific parameters
  final int? numCtx; // Context length
  final int? numGpu; // Number of GPU layers
  final int? numThread; // Number of CPU threads
  final bool? numa; // NUMA support
  final int? numBatch; // Batch size
  final String? keepAlive; // How long to keep model in memory
  final bool? raw; // Raw mode (no templating)
  final bool? reasoning; // Enable thinking for reasoning models

  /// Reference to original LLMConfig for accessing provider options.
  final LLMConfig? _originalConfig;

  const OllamaConfig({
    this.baseUrl = ProviderDefaults.ollamaBaseUrl,
    this.apiKey,
    this.model = ProviderDefaults.ollamaDefaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.jsonSchema,
    // Ollama-specific parameters
    this.numCtx,
    this.numGpu,
    this.numThread,
    this.numa,
    this.numBatch,
    this.keepAlive,
    this.raw,
    this.reasoning,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create OllamaConfig from unified LLMConfig
  factory OllamaConfig.fromLLMConfig(LLMConfig config) {
    const providerId = 'ollama';
    final providerOptions = config.providerOptions;

    return OllamaConfig(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,

      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      // Standard extras (namespaced)
      jsonSchema: readProviderOption<StructuredOutputFormat>(
        providerOptions,
        providerId,
        'jsonSchema',
      ),
      // Ollama-specific provider options (namespaced)
      numCtx: readProviderOption<int>(providerOptions, providerId, 'numCtx'),
      numGpu: readProviderOption<int>(providerOptions, providerId, 'numGpu'),
      numThread:
          readProviderOption<int>(providerOptions, providerId, 'numThread'),
      numa: readProviderOption<bool>(providerOptions, providerId, 'numa'),
      numBatch:
          readProviderOption<int>(providerOptions, providerId, 'numBatch'),
      keepAlive:
          readProviderOption<String>(providerOptions, providerId, 'keepAlive'),
      raw: readProviderOption<bool>(providerOptions, providerId, 'raw'),
      reasoning:
          readProviderOption<bool>(providerOptions, providerId, 'reasoning'),
      originalConfig: config,
    );
  }

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning => true;

  /// Check if this model supports vision
  bool get supportsVision => true;

  /// Check if this model supports tool calling
  bool get supportsToolCalling => true;

  /// Check if this model supports embeddings
  bool get supportsEmbeddings => true;

  /// Check if this model supports code generation
  bool get supportsCodeGeneration => true;

  /// Check if this is a local deployment
  bool get isLocal {
    return baseUrl.contains('localhost') ||
        baseUrl.contains('127.0.0.1') ||
        baseUrl.contains('0.0.0.0');
  }

  /// Get the model family
  String get modelFamily => 'Ollama';

  OllamaConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    StructuredOutputFormat? jsonSchema,
    // Ollama-specific parameters
    int? numCtx,
    int? numGpu,
    int? numThread,
    bool? numa,
    int? numBatch,
    String? keepAlive,
    bool? raw,
    bool? reasoning,
  }) =>
      OllamaConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        topP: topP ?? this.topP,
        topK: topK ?? this.topK,
        tools: tools ?? this.tools,
        jsonSchema: jsonSchema ?? this.jsonSchema,
        numCtx: numCtx ?? this.numCtx,
        numGpu: numGpu ?? this.numGpu,
        numThread: numThread ?? this.numThread,
        numa: numa ?? this.numa,
        numBatch: numBatch ?? this.numBatch,
        keepAlive: keepAlive ?? this.keepAlive,
        raw: raw ?? this.raw,
        reasoning: reasoning ?? this.reasoning,
      );
}
