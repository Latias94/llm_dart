import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

import 'config.dart';

/// Phind Provider implementation.
///
/// Phind is treated as OpenAI-compatible. This provider keeps a thin wrapper
/// and delegates protocol behavior to `llm_dart_openai_compatible`.
class PhindProvider
    implements ChatCapability, ChatStreamPartsCapability, ProviderCapabilities {
  final PhindConfig config;
  final OpenAICompatibleConfig _openAIConfig;
  final OpenAIClient _client;

  late final OpenAICompatibleChatProvider _chat;

  factory PhindProvider(PhindConfig config) {
    final openAIConfig = _toOpenAICompatibleConfig(config);
    final client = OpenAIClient(openAIConfig);
    return PhindProvider._(config, openAIConfig, client);
  }

  PhindProvider._(
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

  String get providerName => 'Phind';

  OpenAIClient get client => _client;

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
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
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) async {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chat.summarizeHistory(messages);
  }

  PhindProvider copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    bool? stream,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
  }) {
    final newConfig = config.copyWith(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      maxTokens: maxTokens,
      temperature: temperature,
      systemPrompt: systemPrompt,
      timeout: timeout,
      topP: topP,
      topK: topK,
      tools: tools,
      toolChoice: toolChoice,
    );

    return PhindProvider(newConfig);
  }

  Map<String, dynamic> get info => {
        'provider': providerName,
        'model': config.model,
        'baseUrl': config.baseUrl,
        'supportsChat': true,
        'supportsStreaming': true,
        'supportsTools': true,
        'supportsVision': false,
        'supportsReasoning': false,
        'supportsCodeGeneration': false,
        'modelFamily': config.modelFamily,
      };

  @override
  String toString() => 'PhindProvider(model: ${config.model})';
}

OpenAICompatibleConfig _toOpenAICompatibleConfig(PhindConfig config) {
  final base = config.originalConfig;

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
    providerOptions: base?.providerOptions ?? const {},
  );

  return OpenAICompatibleConfig.fromLLMConfig(
    llmConfig,
    providerId: 'phind',
    providerName: 'Phind',
  );
}
