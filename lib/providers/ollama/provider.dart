import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioTransportClient;

import '../../core/capability.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../src/compatibility/providers/compat_provider_support.dart';
import '../../src/compatibility/providers/ollama_compat_shell_support.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'completion.dart';
import 'models.dart';

/// Compatibility-first root Ollama provider shell.
///
/// New shared-capability mainlines should prefer the package-owned modern
/// surfaces in `llm_dart_community` where possible. This root provider remains
/// the migration-era adapter that preserves legacy capability interfaces,
/// fallback routing, and residual provider-shaped APIs such as completion and
/// model listing.
class OllamaProvider
    implements
        ChatCapability,
        CompletionCapability,
        EmbeddingCapability,
        ModelListingCapability,
        ProviderCapabilities {
  final OllamaClient _client;
  final OllamaConfig config;

  // Capability modules
  late final OllamaChat _chat;
  late final OllamaCompatShellSupport _compatShell;
  // Legacy-only residual shell for Ollama's provider-shaped /api/generate path.
  late final OllamaCompletion _completion;
  // Provider-owned catalog shell; not part of the shared modern model surface.
  late final OllamaModels _models;

  OllamaProvider(this.config) : _client = OllamaClient(config) {
    final modernProvider = modern_community.Ollama(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      transport: DioTransportClient(dio: _client.dio),
    );

    // Initialize capability modules
    _chat = OllamaChat(_client, config);
    _compatShell = OllamaCompatShellSupport(
      modernProvider: modernProvider,
      config: config,
    );
    _completion = OllamaCompletion(_client, config);
    _models = OllamaModels(_client, config);
  }

  // Chat capability methods
  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return executeCompatChat(
      originalConfig: _compatShell.compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: (config, messages, tools) =>
          _compatShell.canUseChatBridge(messages),
      bridge: () =>
          _compatShell.compatChat
              .chatWithTools(messages, tools, cancelToken: cancelToken),
      fallback: () => _chat.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: _compatShell.compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: (config, messages, tools) =>
          _compatShell.canUseChatBridge(messages),
      bridge: () => _compatShell.compatChat
          .chatStream(messages, tools: tools, cancelToken: cancelToken),
      fallback: () =>
          _chat.chatStream(messages, tools: tools, cancelToken: cancelToken),
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  // Completion capability methods
  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    return _completion.complete(request);
  }

  // Embedding capability methods
  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    final result = await _compatShell.embeddingModel.embed(
      core.EmbedRequest(
        values: input,
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
        ),
      ),
    );

    return result.embeddings;
  }

  // Model listing capability methods
  @override
  Future<List<AIModel>> models({TransportCancellation? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  /// Get provider name
  String get providerName => 'Ollama';

  // ========== ProviderCapabilities ==========

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
