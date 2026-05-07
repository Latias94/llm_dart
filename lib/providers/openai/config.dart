import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides, TransportClient;

import '../../models/tool_models.dart';
import '../../models/chat_models.dart';
import '../../src/config/provider_defaults.dart';
import 'builtin_tools.dart';

/// Compatibility-first root OpenAI configuration.
///
/// This type remains public because the root package still hosts the legacy
/// OpenAI provider surface, including residual Responses, file, assistant,
/// moderation, image, and audio APIs that do not map cleanly to the stable
/// model-first `AI.openai(...).*.model(...)` path yet.
///
/// New code should prefer the stable OpenAI-family provider package and the
/// `AI` facade when it only needs migrated model surfaces.
class OpenAIConfig implements HasDioClientOverrides {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;
  final TransportClient? transportClient;

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

  final double? frequencyPenalty;
  final double? presencePenalty;
  final Map<String, double>? logitBias;
  final int? seed;
  final bool? parallelToolCalls;
  final bool? logprobs;
  final int? topLogprobs;
  final String? verbosity;

  const OpenAIConfig({
    required this.apiKey,
    this.baseUrl = ProviderDefaults.openaiBaseUrl,
    this.model = ProviderDefaults.openaiDefaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.dioOverrides,
    this.transportClient,
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
    this.frequencyPenalty,
    this.presencePenalty,
    this.logitBias,
    this.seed,
    this.parallelToolCalls,
    this.logprobs,
    this.topLogprobs,
    this.verbosity,
  });

  OpenAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    DioClientOverrides? dioOverrides,
    TransportClient? transportClient,
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
    double? frequencyPenalty,
    double? presencePenalty,
    Map<String, double>? logitBias,
    int? seed,
    bool? parallelToolCalls,
    bool? logprobs,
    int? topLogprobs,
    String? verbosity,
  }) =>
      OpenAIConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        dioOverrides: dioOverrides ?? this.dioOverrides,
        transportClient: transportClient ?? this.transportClient,
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
        frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
        presencePenalty: presencePenalty ?? this.presencePenalty,
        logitBias: logitBias ?? this.logitBias,
        seed: seed ?? this.seed,
        parallelToolCalls: parallelToolCalls ?? this.parallelToolCalls,
        logprobs: logprobs ?? this.logprobs,
        topLogprobs: topLogprobs ?? this.topLogprobs,
        verbosity: verbosity ?? this.verbosity,
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
        other.dioOverrides == dioOverrides &&
        other.transportClient == transportClient &&
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
        other.builtInTools == builtInTools &&
        other.frequencyPenalty == frequencyPenalty &&
        other.presencePenalty == presencePenalty &&
        other.logitBias == logitBias &&
        other.seed == seed &&
        other.parallelToolCalls == parallelToolCalls &&
        other.logprobs == logprobs &&
        other.topLogprobs == topLogprobs &&
        other.verbosity == verbosity;
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
      dioOverrides,
      transportClient,
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
      frequencyPenalty,
      presencePenalty,
      logitBias,
      seed,
      parallelToolCalls,
      logprobs,
      topLogprobs,
      verbosity,
    ]);
  }
}
