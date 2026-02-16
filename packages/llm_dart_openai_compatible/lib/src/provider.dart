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
    implements
        ChatCapability,
        ModelIdentityCapability,
        ProviderCapabilities,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatCapability,
        PromptChatCallOptionsCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability,
        ChatCallOptionsCapability {
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
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  @override
  Set<LLMCapability> get supportedCapabilities => _supportedCapabilities;

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(
      messages,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) async {
    return _chat.chatWithTools(
      messages,
      tools,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsWithCallOptions(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _chat.chatWithToolsWithCallOptions(
      messages,
      tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStreamParts(
      messages,
      tools: tools,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamPartsWithCallOptions(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _chat.chatStreamPartsWithCallOptions(
      messages,
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPrompt(
      prompt,
      providerTools: providerTools,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatPromptWithCallOptions(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptWithCallOptions(
      prompt,
      providerTools: providerTools,
      tools: tools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStreamParts(
      prompt,
      tools: tools,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamPartsWithCallOptions(
    Prompt prompt, {
    List<Tool>? tools,
    List<ProviderTool>? providerTools,
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStreamPartsWithCallOptions(
      prompt,
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
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
}

/// OpenAI-compatible provider that also supports embeddings.
class OpenAICompatibleChatEmbeddingProvider extends OpenAICompatibleChatProvider
    implements EmbeddingCapability, EmbeddingCallOptionsCapability {
  late final OpenAIEmbeddings _embeddings;

  OpenAICompatibleChatEmbeddingProvider(
    OpenAIClient client,
    OpenAIRequestConfig config,
    Set<LLMCapability> supportedCapabilities,
  ) : super(client, config, supportedCapabilities) {
    _embeddings = OpenAIEmbeddings(client, config);
  }

  @override
  Future<EmbeddingResponse> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) async {
    return _embeddings.embed(input, cancelToken: cancelToken);
  }

  @override
  Future<EmbeddingResponse> embedWithCallOptions(
    List<String> input, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _embeddings.embedWithCallOptions(
      input,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }
}
