import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

// Local Groq defaults to avoid depending on the main package.
const String _groqDefaultBaseUrl = 'https://api.groq.com/openai/v1/';
const String _groqDefaultModel = 'llama-3.3-70b-versatile';

/// Groq provider configuration built on top of the OpenAI-compatible config.
///
/// This class mirrors the original GroqConfig from the main package so that
/// existing code (and tests) can rely on the same fields and helpers while
/// reusing the shared OpenAI-compatible protocol layer under the hood.
class GroqConfig extends OpenAICompatibleConfig {
  /// Optional request timeout carried over from the unified LLMConfig.
  final Duration? timeout;

  const GroqConfig({
    required super.apiKey,
    super.baseUrl = _groqDefaultBaseUrl,
    super.model = _groqDefaultModel,
    super.maxTokens,
    super.temperature,
    super.systemPrompt,
    this.timeout,
    super.topP,
    super.topK,
    super.tools,
    super.toolChoice,
    super.reasoningEffort,
    super.jsonSchema,
    super.stopSequences,
    super.user,
    super.serviceTier,
    super.originalConfig,
  }) : super(
          providerId: 'groq',
        );

  /// Create GroqConfig from unified LLMConfig (backwards-compatible API).
  factory GroqConfig.fromLLMConfig(LLMConfig config) {
    return GroqConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl.isNotEmpty ? config.baseUrl : _groqDefaultBaseUrl,
      model: config.model.isNotEmpty ? config.model : _groqDefaultModel,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      reasoningEffort: ReasoningEffort.fromString(
        config.getExtension<String>(LLMConfigKeys.reasoningEffort),
      ),
      jsonSchema: config.getExtension<StructuredOutputFormat>(
        LLMConfigKeys.jsonSchema,
      ),
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      originalConfig: config,
    );
  }

  /// Whether this model supports reasoning/thinking (Groq currently doesn't).
  bool get supportsReasoning => false;

  /// Whether this model supports vision.
  bool get supportsVision {
    // Groq supports vision through Llama Vision models.
    return model.contains('vision') || model.contains('llava');
  }

  /// Whether this model supports tool calling.
  bool get supportsToolCalling {
    // Base models don't support tool calling.
    if (model.contains('-base')) {
      return false;
    }

    // Models that support tool calling (mirrors original implementation).
    const supportedModels = [
      'llama-4-scout',
      'llama-4-maverick',
      'qwen-qwq',
      'deepseek-r1-distill',
      'llama-3.3',
      'llama-3.1',
      'gemma2-9b-it',
    ];

    return supportedModels.any(model.contains);
  }

  /// Whether this model supports parallel tool calling.
  bool get supportsParallelToolCalling =>
      supportsToolCalling && !model.contains('gemma2-9b-it');

  /// Whether this provider is optimized for speed (Groq is generally fast).
  bool get isSpeedOptimized => true;

  /// Model family (kept for backwards compatibility with tests).
  String get modelFamily {
    if (model.contains('llama')) return 'Llama';
    if (model.contains('mixtral')) return 'Mixtral';
    if (model.contains('gemma')) return 'Gemma';
    if (model.contains('whisper')) return 'Whisper';
    return 'Unknown';
  }

  /// Backwards-compatible copyWith implementation.
  @override
  GroqConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    String? systemPrompt,
    String? providerId,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    ReasoningEffort? reasoningEffort,
    StructuredOutputFormat? jsonSchema,
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
    Duration? timeout,
  }) {
    return GroqConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      timeout: timeout ?? this.timeout,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      stopSequences: stopSequences ?? this.stopSequences,
      user: user ?? this.user,
      serviceTier: serviceTier ?? this.serviceTier,
      originalConfig: originalConfig,
    );
  }
}
