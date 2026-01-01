import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';

class XAIProvider
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        EmbeddingCapability,
        ProviderCapabilities {
  final XAIConfig config;

  final OpenAICompatibleConfig _openAIConfig;
  final OpenAIClient _client;
  late final OpenAICompatibleChatEmbeddingProvider _provider;

  factory XAIProvider(XAIConfig config) {
    final openAIConfig = _toOpenAICompatibleConfig(config);
    final client = OpenAIClient(openAIConfig);
    return XAIProvider._(config, openAIConfig, client);
  }

  XAIProvider._(
    this.config,
    this._openAIConfig,
    this._client,
  ) {
    _provider = OpenAICompatibleChatEmbeddingProvider(
      _client,
      _openAIConfig,
      supportedCapabilities,
    );
  }

  OpenAIClient get client => _client;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return _provider.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    return _provider.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _provider.chatStream(messages,
        tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _provider.chatStreamParts(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() {
    return _provider.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return _provider.summarizeHistory(messages);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancelToken? cancelToken,
  }) {
    return _provider.embed(input, cancelToken: cancelToken);
  }

  String get providerName => 'xAI';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.liveSearch,
        LLMCapability.embedding,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.vision,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}

OpenAICompatibleConfig _toOpenAICompatibleConfig(XAIConfig config) {
  final base = config.originalConfig;
  final mergedProviderOptions = <String, Map<String, dynamic>>{
    ...?base?.providerOptions,
    'xai': {
      ...?base?.providerOptions['xai'],
      if (config.jsonSchema != null) 'jsonSchema': config.jsonSchema,
      if (config.embeddingEncodingFormat != null)
        'embeddingEncodingFormat': config.embeddingEncodingFormat,
      if (config.embeddingDimensions != null)
        'embeddingDimensions': config.embeddingDimensions,
      if (config.liveSearch != null) 'liveSearch': config.liveSearch,
      if (config.searchParameters != null)
        'searchParameters': config.searchParameters!.toJson(),
    },
  };

  final llmConfig = LLMConfig(
    apiKey: config.apiKey,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt ?? base?.systemPrompt,
    timeout: config.timeout ?? base?.timeout,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools ?? base?.tools,
    providerTools: base?.providerTools,
    toolChoice: config.toolChoice ?? base?.toolChoice,
    stopSequences: base?.stopSequences,
    user: base?.user,
    serviceTier: base?.serviceTier,
    transportOptions: base?.transportOptions ?? const {},
    providerOptions: mergedProviderOptions,
  );

  return OpenAICompatibleConfig.fromLLMConfig(
    llmConfig,
    providerId: 'xai',
    providerName: 'xAI',
  );
}
