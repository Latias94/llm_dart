import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioTransportClient;

import '../../core/capability.dart';
import '../../core/config.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../src/compatibility/legacy_chat_adapter.dart';
import '../../src/compatibility/providers/compat_provider_support.dart';
import '../../src/config/legacy_config_keys.dart';
import 'client.dart';
import 'config.dart';
import 'chat.dart';
import 'completion.dart';
import 'models.dart';

/// Ollama provider implementation
///
/// This provider implements multiple capabilities and delegates
/// to specialized capability modules for different functionalities.
/// Ollama is designed for local deployment and supports various models.
class OllamaProvider
    implements
        ChatCapability,
        CompletionCapability,
        EmbeddingCapability,
        ModelListingCapability,
        ProviderCapabilities {
  final OllamaClient _client;
  final OllamaConfig config;
  final LLMConfig _compatConfig;

  // Capability modules
  late final OllamaChat _chat;
  late final LegacyChatCapabilityAdapter _compatChat;
  late final OllamaCompletion _completion;
  late final core.EmbeddingModel _embeddingModel;
  late final OllamaModels _models;

  OllamaProvider(this.config)
      : _client = OllamaClient(config),
        _compatConfig = _toCompatConfig(config) {
    final modernProvider = modern_community.Ollama(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      transport: DioTransportClient(dio: _client.dio),
    );

    // Initialize capability modules
    _chat = OllamaChat(_client, config);
    _compatChat = LegacyChatCapabilityAdapter(
      model: modernProvider.chatModel(config.model),
      config: _compatConfig,
      providerOptions: _buildCompatProviderOptions(config),
    );
    _completion = OllamaCompletion(_client, config);
    _embeddingModel = modernProvider.embeddingModel(config.model);
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
      originalConfig: _compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: _canUseOllamaChatBridge,
      bridge: () =>
          _compatChat.chatWithTools(messages, tools, cancelToken: cancelToken),
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
      originalConfig: _compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: _canUseOllamaChatBridge,
      bridge: () => _compatChat.chatStream(messages,
          tools: tools, cancelToken: cancelToken),
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
    final result = await _embeddingModel.embed(
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

bool _canUseOllamaChatBridge(
  LLMConfig config,
  List<ChatMessage> messages,
  List<Tool>? tools,
) {
  if (messages.any((message) => message.name != null)) {
    return false;
  }

  final hasConfigSystemPrompt =
      config.systemPrompt != null && config.systemPrompt!.isNotEmpty;
  if (hasConfigSystemPrompt &&
      messages.any((message) => message.role == ChatRole.system)) {
    return false;
  }

  return true;
}

LLMConfig _toCompatConfig(OllamaConfig config) {
  return LLMConfig(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    extensions: {
      if (config.jsonSchema != null)
        LegacyExtensionKeys.jsonSchema: config.jsonSchema!,
      if (config.numCtx != null) LegacyExtensionKeys.numCtx: config.numCtx!,
      if (config.numGpu != null) LegacyExtensionKeys.numGpu: config.numGpu!,
      if (config.numThread != null)
        LegacyExtensionKeys.numThread: config.numThread!,
      if (config.numa != null) LegacyExtensionKeys.numa: config.numa!,
      if (config.numBatch != null)
        LegacyExtensionKeys.numBatch: config.numBatch!,
      if (config.keepAlive != null)
        LegacyExtensionKeys.keepAlive: config.keepAlive!,
      if (config.raw != null) LegacyExtensionKeys.raw: config.raw!,
      if (config.reasoning != null)
        LegacyExtensionKeys.reasoning: config.reasoning!,
    },
  );
}

modern_community.OllamaGenerateTextOptions _buildCompatProviderOptions(
  OllamaConfig config,
) {
  return modern_community.OllamaGenerateTextOptions(
    numCtx: config.numCtx,
    numGpu: config.numGpu,
    numThread: config.numThread,
    numBatch: config.numBatch,
    numa: config.numa,
    keepAlive: config.keepAlive ?? '5m',
    raw: config.raw == true ? true : null,
    reasoning: config.reasoning,
  );
}
