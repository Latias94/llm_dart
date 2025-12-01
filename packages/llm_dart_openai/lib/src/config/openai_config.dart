import 'package:llm_dart_core/llm_dart_core.dart';

import '../tools/openai_builtin_tools.dart';

/// Public defaults for OpenAI base URL and model.
///
/// These constants provide a single source of truth for OpenAI defaults
/// across the SDK (registry, high-level factories, helpers, etc.).
const String openaiDefaultBaseUrl = 'https://api.openai.com/v1/';
const String openaiDefaultModel = 'gpt-4o';

// Internal aliases used by this config class. Keeping a private copy
// allows us to change internal usage without affecting public API.
const String _openaiDefaultBaseUrl = openaiDefaultBaseUrl;
const String _openaiDefaultModel = openaiDefaultModel;

/// OpenAI provider configuration
///
/// This class contains all configuration options for the OpenAI providers.
/// It's extracted from the main provider to improve modularity and reusability.
class OpenAIConfig implements ProviderHttpConfig {
  @override
  final String apiKey;

  @override
  final String baseUrl;

  @override
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final ReasoningEffort? reasoningEffort;
  final StructuredOutputFormat? jsonSchema;
  final String? voice;
  final String? embeddingEncodingFormat;
  final int? embeddingDimensions;
  final List<String>? stopSequences;
  final String? user;
  final ServiceTier? serviceTier;

  /// Whether to use the new Responses API instead of Chat Completions API
  final bool useResponsesAPI;

  /// Previous response ID for chaining responses (Responses API only)
  final String? previousResponseId;

  /// Built-in tools to use with Responses API
  final List<OpenAIBuiltInTool>? builtInTools;

  /// Reference to original LLMConfig for accessing extensions
  final LLMConfig? _originalConfig;

  const OpenAIConfig({
    required this.apiKey,
    this.baseUrl = _openaiDefaultBaseUrl,
    this.model = _openaiDefaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.reasoningEffort,
    this.jsonSchema,
    this.voice,
    this.embeddingEncodingFormat,
    this.embeddingDimensions,
    this.stopSequences,
    this.user,
    this.serviceTier,
    this.useResponsesAPI = false,
    this.previousResponseId,
    this.builtInTools,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Build an [OpenAIConfig] from a unified [LLMConfig].
  ///
  /// This maps common fields (baseUrl, model, sampling parameters, tools,
  /// stop sequences, user, service tier) and OpenAI-specific extensions
  /// (reasoningEffort, jsonSchema, voice, embeddingEncodingFormat,
  /// embeddingDimensions, Responses API options). Web-search-specific
  /// model switching and built-in tool inference are handled separately
  /// in the provider factory.
  factory OpenAIConfig.fromLLMConfig(LLMConfig config) {
    final apiKey = config.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const GenericError(
        'OpenAIConfig.fromLLMConfig requires a non-empty apiKey in LLMConfig.',
      );
    }

    // Fall back to OpenAI defaults when baseUrl/model are empty strings.
    final baseUrl =
        config.baseUrl.isNotEmpty ? config.baseUrl : openaiDefaultBaseUrl;
    final model = config.model.isNotEmpty ? config.model : openaiDefaultModel;

    return OpenAIConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      reasoningEffort: ReasoningEffort.fromString(
        config.getExtension<String>(LLMConfigKeys.reasoningEffort),
      ),
      jsonSchema: config.getExtension<StructuredOutputFormat>(
        LLMConfigKeys.jsonSchema,
      ),
      voice: config.getExtension<String>(LLMConfigKeys.voice),
      embeddingEncodingFormat: config.getExtension<String>(
        LLMConfigKeys.embeddingEncodingFormat,
      ),
      embeddingDimensions: config.getExtension<int>(
        LLMConfigKeys.embeddingDimensions,
      ),
      useResponsesAPI:
          config.getExtension<bool>(LLMConfigKeys.useResponsesAPI) ?? false,
      previousResponseId:
          config.getExtension<String>(LLMConfigKeys.previousResponseId),
      builtInTools: config.getExtension<List<OpenAIBuiltInTool>>(
        LLMConfigKeys.builtInTools,
      ),
      originalConfig: config,
    );
  }

  /// Get extension value from original config
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  /// Get the original LLMConfig for HTTP configuration
  @override
  LLMConfig? get originalConfig => _originalConfig;

  OpenAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    ReasoningEffort? reasoningEffort,
    StructuredOutputFormat? jsonSchema,
    String? voice,
    String? embeddingEncodingFormat,
    int? embeddingDimensions,
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
    bool? useResponsesAPI,
    String? previousResponseId,
    List<OpenAIBuiltInTool>? builtInTools,
  }) =>
      OpenAIConfig(
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
        voice: voice ?? this.voice,
        embeddingEncodingFormat:
            embeddingEncodingFormat ?? this.embeddingEncodingFormat,
        embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
        stopSequences: stopSequences ?? this.stopSequences,
        user: user ?? this.user,
        serviceTier: serviceTier ?? this.serviceTier,
        useResponsesAPI: useResponsesAPI ?? this.useResponsesAPI,
        previousResponseId: previousResponseId ?? this.previousResponseId,
        builtInTools: builtInTools ?? this.builtInTools,
      );

  @override
  String toString() {
    return 'OpenAIConfig('
        'model: $model, '
        'baseUrl: $baseUrl, '
        'maxTokens: $maxTokens, '
        'temperature: $temperature'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OpenAIConfig &&
        other.apiKey == apiKey &&
        other.baseUrl == baseUrl &&
        other.model == model &&
        other.maxTokens == maxTokens &&
        other.temperature == temperature &&
        other.systemPrompt == systemPrompt &&
        other.timeout == timeout &&
        other.topP == topP &&
        other.topK == topK &&
        other.tools == tools &&
        other.toolChoice == toolChoice &&
        other.reasoningEffort == reasoningEffort &&
        other.jsonSchema == jsonSchema &&
        other.voice == voice &&
        other.embeddingEncodingFormat == embeddingEncodingFormat &&
        other.embeddingDimensions == embeddingDimensions &&
        other.stopSequences == stopSequences &&
        other.user == user &&
        other.serviceTier == serviceTier &&
        other.useResponsesAPI == useResponsesAPI &&
        other.previousResponseId == previousResponseId &&
        other.builtInTools == builtInTools;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      apiKey,
      baseUrl,
      model,
      maxTokens,
      temperature,
      systemPrompt,
      timeout,
      topP,
      topK,
      tools,
      toolChoice,
      reasoningEffort,
      jsonSchema,
      voice,
      embeddingEncodingFormat,
      embeddingDimensions,
      stopSequences,
      user,
      serviceTier,
      useResponsesAPI,
      previousResponseId,
      builtInTools,
    ]);
  }
}
