import 'package:llm_dart_core/llm_dart_core.dart';

/// Ollama provider configuration for the sub-package.
class OllamaConfig implements ProviderHttpConfig {
  @override
  final String baseUrl;
  @override
  final String? apiKey;
  @override
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
  final int? numCtx;
  final int? numGpu;
  final int? numThread;
  final bool? numa;
  final int? numBatch;
  final String? keepAlive;
  final bool? raw;
  final bool? reasoning;

  final LLMConfig? _originalConfig;

  const OllamaConfig({
    this.baseUrl = 'http://localhost:11434/',
    this.apiKey,
    this.model = 'llama3.2',
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.jsonSchema,
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

  factory OllamaConfig.fromLLMConfig(LLMConfig config) {
    return OllamaConfig(
      baseUrl: config.baseUrl.isNotEmpty
          ? config.baseUrl
          : 'http://localhost:11434/',
      apiKey: config.apiKey,
      model: config.model.isNotEmpty ? config.model : 'llama3.2',
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      jsonSchema: config.getExtension<StructuredOutputFormat>(
        LLMConfigKeys.jsonSchema,
      ),
      numCtx: config.getExtension<int>(LLMConfigKeys.numCtx),
      numGpu: config.getExtension<int>(LLMConfigKeys.numGpu),
      numThread: config.getExtension<int>(LLMConfigKeys.numThread),
      numa: config.getExtension<bool>(LLMConfigKeys.numa),
      numBatch: config.getExtension<int>(LLMConfigKeys.numBatch),
      keepAlive: config.getExtension<String>(LLMConfigKeys.keepAlive),
      raw: config.getExtension<bool>(LLMConfigKeys.raw),
      reasoning: config.getExtension<bool>(LLMConfigKeys.reasoning),
      originalConfig: config,
    );
  }

  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  @override
  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsReasoning {
    return model.contains('reasoning') ||
        model.contains('think') ||
        model.contains('qwen2.5') ||
        model.contains('gpt-oss') ||
        model.contains('deepseek-r1');
  }

  bool get supportsVision {
    return model.contains('vision') ||
        model.contains('llava') ||
        model.contains('llava-llama') ||
        model.contains('moondream') ||
        model.contains('minicpm');
  }

  bool get supportsToolCalling {
    // If explicit tools are configured, assume tool calling is supported.
    if (tools != null && tools!.isNotEmpty) {
      return true;
    }

    final lowerModel = model.toLowerCase();

    // Heuristics based on common Ollama model families that support tools.
    final isLlamaTools =
        lowerModel.contains('llama3') || lowerModel.contains('llama-3');
    final isMistral = lowerModel.contains('mistral');
    final isQwen = lowerModel.contains('qwen');
    final isPhi3 = lowerModel.contains('phi3');

    return isLlamaTools || isMistral || isQwen || isPhi3;
  }

  bool get supportsEmbeddings {
    return model.contains('embed') ||
        model.contains('nomic') ||
        model.contains('mxbai') ||
        model.contains('all-minilm');
  }

  bool get supportsCodeGeneration {
    return model.contains('codellama') ||
        model.contains('codegemma') ||
        model.contains('starcoder') ||
        model.contains('deepseek-coder');
  }

  String get modelFamily {
    if (model.contains('codellama')) return 'Code Llama';
    if (model.contains('llava')) return 'LLaVA';
    if (model.contains('llama')) return 'Llama';
    if (model.contains('mistral')) return 'Mistral';
    if (model.contains('qwen')) return 'Qwen';
    if (model.contains('phi')) return 'Phi';
    if (model.contains('gemma')) return 'Gemma';
    return 'Unknown';
  }

  bool get isLocal {
    return baseUrl.contains('localhost') ||
        baseUrl.contains('127.0.0.1') ||
        baseUrl.contains('0.0.0.0');
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
    int? numCtx,
    int? numGpu,
    int? numThread,
    bool? numa,
    int? numBatch,
    String? keepAlive,
    bool? raw,
    bool? reasoning,
  }) {
    return OllamaConfig(
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
      originalConfig: _originalConfig,
    );
  }
}
