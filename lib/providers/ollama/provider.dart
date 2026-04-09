import '../../core/capability.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../src/compatibility/providers/ollama_compat_shell_support.dart';
import 'config.dart';

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
  final OllamaConfig config;
  final OllamaCompatShellSupport _compatShell;

  OllamaProvider(this.config)
      : _compatShell = OllamaCompatShellSupport(config: config);

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
    return _compatShell.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _compatShell.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _compatShell.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _compatShell.summarizeHistory(messages);
  }

  // Completion capability methods
  @override
  Future<CompletionResponse> complete(CompletionRequest request) async {
    return _compatShell.complete(request);
  }

  // Embedding capability methods
  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    TransportCancellation? cancelToken,
  }) async {
    return _compatShell.embed(input, cancelToken: cancelToken);
  }

  // Model listing capability methods
  @override
  Future<List<AIModel>> models({TransportCancellation? cancelToken}) async {
    return _compatShell.models(cancelToken: cancelToken);
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
