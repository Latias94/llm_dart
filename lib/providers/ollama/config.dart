import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides;

import '../../models/tool_models.dart';
import 'defaults.dart';

/// Ollama provider configuration
///
/// This class contains all configuration options for the Ollama providers.
/// It's extracted from the main provider to improve modularity and reusability.
class OllamaConfig implements HasDioClientOverrides {
  final String baseUrl;
  final String? apiKey;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;

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

  const OllamaConfig({
    this.baseUrl = OllamaDefaults.baseUrl,
    this.apiKey,
    this.model = OllamaDefaults.defaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.dioOverrides,
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
  });

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
    DioClientOverrides? dioOverrides,
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
        dioOverrides: dioOverrides ?? this.dioOverrides,
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
