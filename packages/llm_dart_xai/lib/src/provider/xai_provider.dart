// xAI provider implementation built on ChatMessage-based chat and
// embedding capabilities from llm_dart_core. ChatMessage usage is
// intentional here for compatibility with existing helpers.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart_core/llm_dart_core.dart';

import '../chat/xai_chat.dart';
import '../client/xai_client.dart';
import '../config/xai_config.dart';
import '../config/search_parameters.dart';
import '../embeddings/xai_embeddings.dart';

class XAIProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {
  final XAIClient _client;
  final XAIConfig config;

  late final XAIChat _chat;
  late final XAIEmbeddings _embeddings;

  XAIProvider(this.config) : _client = XAIClient(config) {
    _chat = XAIChat(_client, config);
    _embeddings = XAIEmbeddings(_client, config);
  }

  String get providerName => 'xAI';

  /// Superset of capabilities that xAI models can support.
  ///
  /// Individual models may only support a subset of these at runtime,
  /// as reflected by [supportedCapabilities].
  static const Set<LLMCapability> baseCapabilities = {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.embedding,
    LLMCapability.toolCalling,
    LLMCapability.vision,
    LLMCapability.reasoning,
    LLMCapability.liveSearch,
  };

  /// Expose client for tests and advanced usage.
  XAIClient get client => _client;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chat(
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatWithTools(
      messages,
      tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatStream(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() => _chat.memoryContents();

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      _chat.summarizeHistory(messages);

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  @override
  Set<LLMCapability> get supportedCapabilities {
    final capabilities = <LLMCapability>{
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.embedding,
    };

    if (config.supportsToolCalling) {
      capabilities.add(LLMCapability.toolCalling);
    }
    if (config.supportsVision) {
      capabilities.add(LLMCapability.vision);
    }
    if (config.supportsReasoning) {
      capabilities.add(LLMCapability.reasoning);
    }
    if (config.supportsSearch || config.isLiveSearchEnabled) {
      capabilities.add(LLMCapability.liveSearch);
    }

    return capabilities;
  }

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  XAIProvider copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    bool? stream,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? jsonSchema,
    String? embeddingEncodingFormat,
    int? embeddingDimensions,
    SearchParameters? searchParameters,
    bool? liveSearch,
  }) {
    final newConfig = config.copyWith(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      systemPrompt: systemPrompt,
      timeout: timeout,
      topP: topP,
      topK: topK,
      tools: tools,
      toolChoice: toolChoice,
      jsonSchema: jsonSchema,
      embeddingEncodingFormat: embeddingEncodingFormat,
      embeddingDimensions: embeddingDimensions,
      searchParameters: searchParameters,
      liveSearch: liveSearch,
    );

    return XAIProvider(newConfig);
  }

  Map<String, dynamic> get info => {
        'provider': providerName,
        'model': config.model,
        'baseUrl': config.baseUrl,
        'supportsChat': true,
        'supportsStreaming': true,
        'supportsTools': config.supportsToolCalling,
        'supportsVision': config.supportsVision,
        'supportsReasoning': config.supportsReasoning,
        'supportsSearch': config.supportsSearch,
        'supportsLiveSearch': config.isLiveSearchEnabled,
        'supportsEmbeddings': config.supportsEmbeddings,
        'modelFamily': config.modelFamily,
        'capabilities': supportedCapabilities.map((c) => c.name).toList(),
      };

  @override
  String toString() => 'XAIProvider(model: ${config.model})';
}
