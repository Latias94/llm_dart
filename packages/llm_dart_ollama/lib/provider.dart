import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'embeddings.dart';

/// Ollama provider implementation
///
/// This provider implements multiple capabilities and delegates
/// to specialized capability modules for different functionalities.
/// Ollama is designed for local deployment and supports various models.
class OllamaProvider
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        EmbeddingCapability,
        ProviderCapabilities {
  final OllamaClient _client;
  final OllamaConfig config;

  // Capability modules
  late final OllamaChat _chat;
  late final OllamaEmbeddings _embeddings;

  OllamaProvider(this.config) : _client = OllamaClient(config) {
    // Initialize capability modules
    _chat = OllamaChat(_client, config);
    _embeddings = OllamaEmbeddings(_client, config);
  }

  // Chat capability methods
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

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
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStreamParts(messages,
        tools: tools, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  // Embedding capability methods
  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  /// Get provider name
  String get providerName => 'Ollama';

  // ========== ProviderCapabilities ==========

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.toolCalling,
        LLMCapability.vision,
        LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  /// Get model family information
  String get modelFamily => config.modelFamily;

  /// Check if this is a local deployment
  bool get isLocal => config.isLocal;

  /// Check if embeddings are supported by current model
  bool get supportsEmbeddings => config.supportsEmbeddings;
}
