import 'package:dio/dio.dart';

import '../../core/capability.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import 'chat.dart';
import 'client.dart';
import 'config.dart';
import 'embeddings.dart';

/// xAI Provider implementation
///
/// This is the main provider class that implements capability interfaces
/// and delegates to specialized modules for different functionalities.
///
/// **Supported Capabilities:**
/// - Chat with Grok models
/// - Real-time web search (Live Search)
/// - Function/tool calling
/// - Vector embeddings
/// - Reasoning and thinking (Grok models)
/// - Vision capabilities (Grok Vision models)
class XAIProvider
    implements ChatCapability, EmbeddingCapability, ProviderCapabilities {
  final XAIConfig config;
  final XAIClient client;

  // Capability modules
  late final XAIChat _chat;
  late final XAIEmbedding _embedding;

  XAIProvider(this.config) : client = XAIClient(config) {
    _chat = XAIChat(client, config);
    _embedding = XAIEmbedding(client, config);
  }

  String get providerName => 'xAI';

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStream(messages, tools: tools, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embedding.embed(input, cancelToken: cancelToken);
  }

  @override
  Set<LLMCapability> get supportedCapabilities {
    final capabilities = <LLMCapability>{
      LLMCapability.chat,
      LLMCapability.streaming,
      LLMCapability.embedding,
    };

    // Add capabilities based on model and configuration
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

  /// Create a new provider with updated configuration
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

  /// Check if the provider supports a specific capability
  bool supportsCapability(Type capability) {
    if (capability == ChatCapability) return true;
    // Add other capabilities as they are implemented
    return false;
  }

  /// Get provider information
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
