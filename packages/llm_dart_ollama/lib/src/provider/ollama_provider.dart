import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import '../chat/ollama_chat.dart';
import '../client/ollama_client.dart';
import '../completion/ollama_completion.dart';
import '../config/ollama_config.dart';
import '../embeddings/ollama_embeddings.dart';
import '../models/ollama_models.dart';

class OllamaProvider
    implements
        ChatCapability,
        CompletionCapability,
        EmbeddingCapability,
        ModelListingCapability,
        ProviderCapabilities {
  final OllamaClient _client;
  final OllamaConfig config;

  late final OllamaChat _chat;
  late final OllamaCompletion _completion;
  late final OllamaEmbeddings _embeddings;
  late final OllamaModels _models;

  OllamaProvider(this.config) : _client = OllamaClient(config) {
    _chat = OllamaChat(_client, config);
    _completion = OllamaCompletion(_client, config);
    _embeddings = OllamaEmbeddings(_client, config);
    _models = OllamaModels(_client, config);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
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
  Future<List<ChatMessage>?> memoryContents() => _chat.memoryContents();

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      _chat.summarizeHistory(messages);

  @override
  Future<CompletionResponse> complete(CompletionRequest request) {
    return _completion.complete(request);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) {
    return _models.models(cancelToken: cancelToken);
  }

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.completion,
        LLMCapability.embedding,
        LLMCapability.modelListing,
        if (config.supportsToolCalling) LLMCapability.toolCalling,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);

  /// Get provider name for diagnostics.
  String get providerName => 'Ollama';

  /// Check if this is a local deployment.
  bool get isLocal => config.isLocal;

  /// Get model family information.
  String get modelFamily => config.modelFamily;

  /// Check if embeddings are supported by current model.
  bool get supportsEmbeddings => config.supportsEmbeddings;
}
