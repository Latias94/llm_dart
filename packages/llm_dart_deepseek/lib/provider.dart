import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

import 'config.dart';
import 'models.dart';

/// DeepSeek provider implementation
///
/// DeepSeek is an OpenAI-compatible API surface. This provider is intentionally
/// thin and delegates protocol behavior to `llm_dart_openai_compatible`.
class DeepSeekProvider
    implements
        ChatCapability,
        ChatStreamPartsCapability,
        ModelListingCapability,
        ProviderCapabilities {
  final DeepSeekConfig config;
  final OpenAICompatibleConfig _openAIConfig;
  final OpenAIClient _client;

  late final OpenAICompatibleChatProvider _chat;
  late final DeepSeekModels _models;

  factory DeepSeekProvider(DeepSeekConfig config) {
    final openAIConfig = _toOpenAICompatibleConfig(config);
    final client = OpenAIClient(openAIConfig);
    return DeepSeekProvider._(config, openAIConfig, client);
  }

  DeepSeekProvider._(
    this.config,
    this._openAIConfig,
    this._client,
  ) {
    _chat = OpenAICompatibleChatProvider(
      _client,
      _openAIConfig,
      supportedCapabilities,
    );
    _models = DeepSeekModels(_client, config);
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
    return _chat.chatStreamParts(
      messages,
      tools: tools,
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

  @override
  Future<List<AIModel>> models({CancelToken? cancelToken}) async {
    return _models.models(cancelToken: cancelToken);
  }

  /// Get provider name
  String get providerName => 'DeepSeek';

  // ========== ProviderCapabilities ==========

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.modelListing,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.vision,
        LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}

OpenAICompatibleConfig _toOpenAICompatibleConfig(DeepSeekConfig config) {
  final base = config.originalConfig;
  final mergedProviderOptions = <String, Map<String, dynamic>>{
    ...?base?.providerOptions,
    'deepseek': {
      ...?base?.providerOptions['deepseek'],
      if (config.logprobs != null) 'logprobs': config.logprobs,
      if (config.topLogprobs != null) 'topLogprobs': config.topLogprobs,
      if (config.frequencyPenalty != null)
        'frequencyPenalty': config.frequencyPenalty,
      if (config.presencePenalty != null)
        'presencePenalty': config.presencePenalty,
      if (config.responseFormat != null)
        'responseFormat': config.responseFormat,
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
    providerId: 'deepseek',
    providerName: 'DeepSeek',
  );
}
