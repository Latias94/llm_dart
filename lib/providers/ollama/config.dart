import '../../models/tool_models.dart';
import '../../core/config.dart';
import '../../core/provider_defaults.dart';

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

  /// Reference to original LLMConfig for accessing extensions
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
      // Ollama-specific extensions
      jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
      numCtx: config.getExtension<int>('numCtx'),
      numGpu: config.getExtension<int>('numGpu'),
      numThread: config.getExtension<int>('numThread'),
      numa: config.getExtension<bool>('numa'),
      numBatch: config.getExtension<int>('numBatch'),
      keepAlive: config.getExtension<String>('keepAlive'),
      raw: config.getExtension<bool>('raw'),
      reasoning: config.getExtension<bool>('reasoning'),
      originalConfig: config,
    );
  }

  /// Get extension value from original config
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning {
    // Some Ollama models support reasoning, especially newer ones
    return model.contains('reasoning') ||
        model.contains('think') ||
        model.contains('qwen2.5') ||
        model.contains('gpt-oss') ||
        model.contains('deepseek-r1');
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Ollama supports vision through specific models
    return model.contains('vision') ||
        model.contains('llava') ||
        model.contains('minicpm') ||
        model.contains('moondream');
  }

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // Many Ollama models support tool calling
    return model.contains('llama3') ||
        model.contains('mistral') ||
        model.contains('qwen') ||
        model.contains('phi3');
  }

  /// Check if this model supports embeddings
  bool get supportsEmbeddings {
    // Embedding models in Ollama
    return model.contains('embed') ||
        model.contains('nomic') ||
        model.contains('mxbai') ||
        model.contains('all-minilm');
  }

  /// Check if this model supports code generation
  bool get supportsCodeGeneration {
    // Code-focused models
    return model.contains('codellama') ||
        model.contains('codegemma') ||
        model.contains('starcoder') ||
        model.contains('deepseek-coder');
  }

  /// Check if this is a local deployment
  bool get isLocal {
    return baseUrl.contains('localhost') ||
        baseUrl.contains('127.0.0.1') ||
        baseUrl.contains('0.0.0.0');
  }

  /// Get the model family
  String get modelFamily {
    // Check more specific models first
    if (model.contains('codellama')) return 'Code Llama';
    if (model.contains('llava')) return 'LLaVA';
    if (model.contains('llama')) return 'Llama';
    if (model.contains('mistral')) return 'Mistral';
    if (model.contains('qwen')) return 'Qwen';
    if (model.contains('phi')) return 'Phi';
    if (model.contains('gemma')) return 'Gemma';
    return 'Unknown';
  }

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
