import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/openai_request_config.dart'
    show OpenAIRequestConfig;
import 'package:llm_dart_openai_compatible/openai_responses_config.dart'
    show OpenAIResponsesConfig;
import 'package:llm_dart_openai_compatible/builtin_tools.dart';
import '../defaults.dart';

/// OpenAI provider configuration
///
/// This class contains all configuration options for the OpenAI providers.
/// It's extracted from the main provider to improve modularity and reusability.
class OpenAIConfig implements OpenAIRequestConfig, OpenAIResponsesConfig {
  @override
  String get providerId => 'openai';

  @override
  String get providerName => 'OpenAI';

  @override
  final String apiKey;
  @override
  final String baseUrl;
  @override
  final String model;

  @override
  final Map<String, dynamic>? extraBody;

  @override
  final Map<String, String>? extraHeaders;
  @override
  final int? maxTokens;
  @override
  final double? temperature;
  @override
  final String? systemPrompt;
  @override
  final Duration? timeout;

  @override
  final double? topP;
  @override
  final int? topK;
  @override
  final List<Tool>? tools;
  @override
  final ToolChoice? toolChoice;
  @override
  final ReasoningEffort? reasoningEffort;
  @override
  final StructuredOutputFormat? jsonSchema;
  @override
  final String? voice;
  @override
  final String? embeddingEncodingFormat;
  @override
  final int? embeddingDimensions;
  @override
  final List<String>? stopSequences;
  @override
  final String? user;
  @override
  final ServiceTier? serviceTier;

  /// Whether to use the new Responses API instead of Chat Completions API
  final bool useResponsesAPI;

  /// Previous response ID for chaining responses (Responses API only)
  final String? previousResponseId;

  /// Built-in tools to use with Responses API
  final List<OpenAIBuiltInTool>? builtInTools;

  /// Reference to original LLMConfig for accessing provider options.
  final LLMConfig? _originalConfig;

  const OpenAIConfig({
    required this.apiKey,
    this.baseUrl = openaiBaseUrl,
    this.model = openaiDefaultModel,
    this.extraBody,
    this.extraHeaders,
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

  @override
  T? getProviderOption<T>(String key) =>
      _originalConfig?.getProviderOption<T>(providerId, key);

  /// Get the original LLMConfig for HTTP configuration
  @override
  LLMConfig? get originalConfig => _originalConfig;

  OpenAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    Map<String, dynamic>? extraBody,
    Map<String, String>? extraHeaders,
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
        extraBody: extraBody ?? this.extraBody,
        extraHeaders: extraHeaders ?? this.extraHeaders,
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
        other.extraBody == extraBody &&
        other.extraHeaders == extraHeaders &&
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
      extraBody,
      extraHeaders,
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
