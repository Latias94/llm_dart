// Ollama provider implementation built on ChatMessage-based
// capabilities from llm_dart_core. ChatMessage usage is intentional
// here for compatibility with existing helpers.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../chat/ollama_chat.dart';
import '../client/ollama_client.dart';
import '../completion/ollama_completion.dart';
import '../config/ollama_config.dart';
import '../embeddings/ollama_embeddings.dart';
import '../models/ollama_models.dart';

class OllamaProvider
    implements
        ChatCapability,
        PromptChatCapability,
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
  Future<CompletionResponse> complete(CompletionRequest request) {
    return _completion.complete(request);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) {
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

  /// Show detailed information about a model.
  Future<Map<String, dynamic>> showModel(
    String model, {
    CancellationToken? cancelToken,
  }) {
    return _client.showModel(
      model,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  /// Copy a model to a new name.
  Future<void> copyModel(
    String source,
    String destination, {
    CancellationToken? cancelToken,
  }) {
    return _client.copyModel(
      source,
      destination,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  /// Delete a model and its data.
  Future<void> deleteModel(
    String model, {
    CancellationToken? cancelToken,
  }) {
    return _client.deleteModel(
      model,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  /// Pull a model from the Ollama library.
  Future<Map<String, dynamic>> pullModel(
    String model, {
    bool insecure = false,
    CancellationToken? cancelToken,
  }) {
    return _client.pullModel(
      model,
      insecure: insecure,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  /// Push a model to a remote library.
  Future<Map<String, dynamic>> pushModel(
    String model, {
    bool insecure = false,
    CancellationToken? cancelToken,
  }) {
    return _client.pushModel(
      model,
      insecure: insecure,
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  /// List models currently loaded into memory.
  Future<List<Map<String, dynamic>>> listRunningModels({
    CancellationToken? cancelToken,
  }) {
    return _client.listRunningModels(
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  /// Get Ollama server version information.
  Future<Map<String, dynamic>> serverVersion({
    CancellationToken? cancelToken,
  }) {
    return _client.version(
      cancelToken: CancellationUtils.toDioCancelToken(cancelToken),
    );
  }

  // ===== PromptChatCapability (prompt-first) =====

  @override
  Future<ChatResponse> chatPrompt(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatPrompt(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatPromptStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatPromptStream(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
