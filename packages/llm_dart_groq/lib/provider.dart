import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';

/// Groq provider implementation
///
/// Groq is an OpenAI-compatible API surface. This provider is intentionally
/// thin and delegates protocol behavior to `llm_dart_openai_compatible`.
class GroqProvider
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
        ModelIdentityCapability,
        ProviderCapabilities {
  final GroqConfig config;
  final OpenAICompatibleConfig _openAIConfig;
  final OpenAIClient _client;

  late final OpenAICompatibleChatProvider _chat;

  factory GroqProvider(GroqConfig config) {
    final openAIConfig = _toOpenAICompatibleConfig(config);
    final client = OpenAIClient(openAIConfig);
    return GroqProvider._(config, openAIConfig, client);
  }

  GroqProvider._(
    this.config,
    this._openAIConfig,
    this._client,
  ) {
    _chat = OpenAICompatibleChatProvider(
      _client,
      _openAIConfig,
      supportedCapabilities,
    );
  }

  @override
  String get providerId => 'groq';

  @override
  String get modelId => config.model;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
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
  }) {
    return _chat.chatWithTools(
      messages,
      tools,
      providerTools: providerTools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
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
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
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
  Future<List<ChatMessage>?> memoryContents() {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return _chat.summarizeHistory(messages);
  }

  String get providerName => 'Groq';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.vision,
        LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  String get modelFamily => config.modelFamily;

  bool get isSpeedOptimized => config.isSpeedOptimized;
}

OpenAICompatibleConfig _toOpenAICompatibleConfig(GroqConfig config) {
  final base = config.originalConfig;
  final mergedProviderOptions = <String, Map<String, dynamic>>{
    ...?base?.providerOptions,
    'groq': {
      ...?base?.providerOptions['groq'],
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
    providerId: 'groq',
    providerName: 'Groq',
  );
}
