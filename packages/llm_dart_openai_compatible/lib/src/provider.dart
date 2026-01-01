import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat.dart';
import 'client.dart';
import 'embeddings.dart';
import 'openai_request_config.dart';

/// Minimal provider implementation for OpenAI-compatible APIs.
///
/// This is used by `llm_dart_openai_compatible` factories so users can depend
/// on OpenAI-compatible providers without pulling in `llm_dart_openai`.
class OpenAICompatibleChatProvider
    implements ChatCapability, ProviderCapabilities, ChatStreamPartsCapability {
  final OpenAIClient _client;
  final OpenAIRequestConfig config;
  final Set<LLMCapability> _supportedCapabilities;

  late final OpenAIChat _chat;

  OpenAICompatibleChatProvider(
    this._client,
    this.config,
    this._supportedCapabilities,
  ) {
    _chat = OpenAIChat(_client, config);
  }

  @override
  Set<LLMCapability> get supportedCapabilities => _supportedCapabilities;

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

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
}

/// OpenAI-compatible provider that also supports embeddings.
class OpenAICompatibleChatEmbeddingProvider extends OpenAICompatibleChatProvider
    implements EmbeddingCapability {
  late final OpenAIEmbeddings _embeddings;

  OpenAICompatibleChatEmbeddingProvider(
    OpenAIClient client,
    OpenAIRequestConfig config,
    Set<LLMCapability> supportedCapabilities,
  ) : super(client, config, supportedCapabilities) {
    _embeddings = OpenAIEmbeddings(client, config);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }
}
