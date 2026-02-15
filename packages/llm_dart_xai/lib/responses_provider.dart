import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'responses.dart';

/// xAI provider using the Responses API (`POST /v1/responses`).
///
/// Registry id: `xai.responses` (Vercel-style).
class XAIResponsesProvider
    implements
        ChatCapability,
        ModelIdentityCapability,
        ChatStreamPartsCapability,
        ChatStreamPartsCallOptionsCapability,
        PromptChatCapability,
        PromptChatStreamPartsCapability,
        PromptChatStreamPartsCallOptionsCapability,
        ChatCallOptionsCapability,
        PromptChatCallOptionsCapability,
        ProviderCapabilities {
  final OpenAICompatibleConfig config;
  final OpenAIClient _client;
  late final XAIResponses _responses;

  factory XAIResponsesProvider(LLMConfig llmConfig) {
    final openAIConfig = OpenAICompatibleConfig.fromLLMConfig(
      llmConfig,
      providerId: 'xai.responses',
      providerName: 'xAI (Responses)',
    );
    final client = OpenAIClient(openAIConfig);
    return XAIResponsesProvider._(openAIConfig, client);
  }

  XAIResponsesProvider._(this.config, this._client) {
    _responses = XAIResponses(_client, config);
  }

  @override
  String get providerId => config.providerId;

  @override
  String get modelId => config.model;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    List<ProviderTool>? providerTools,
    CancelToken? cancelToken,
  }) {
    return _responses.chat(
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
    return _responses.chatWithTools(
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
    return _responses.chatWithToolsWithCallOptions(
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
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _responses.chatStreamParts(
      messages,
      providerTools: providerTools,
      tools: tools,
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
    return _responses.chatStreamPartsWithCallOptions(
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
    return _responses.chatPrompt(
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
    return _responses.chatPromptWithCallOptions(
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
    List<ProviderTool>? providerTools,
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _responses.chatPromptStreamParts(
      prompt,
      providerTools: providerTools,
      tools: tools,
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
    return _responses.chatPromptStreamPartsWithCallOptions(
      prompt,
      tools: tools,
      providerTools: providerTools,
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    final prompt = 'Summarize in 2-3 sentences:\n'
        '${messages.map((m) => '${m.role.name}: ${m.content}').join('\n')}';
    final response = await chat([ChatMessage.user(prompt)]);
    final text = response.text;
    if (text == null) {
      throw const FormatException('no text in summary response');
    }
    return text;
  }

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.liveSearch,
        LLMCapability.openaiResponses,
        // Intentionally optimistic: do not maintain a model capability matrix.
        LLMCapability.vision,
      };

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}

/// Convenience constructor for the xAI Responses provider (`xai.responses`).
///
/// This is intentionally Tier 3 / opt-in: import via
/// `package:llm_dart_xai/responses_provider.dart`.
XAIResponsesProvider createXAIResponsesProvider({
  required String apiKey,
  String model = 'grok-4-fast',
  String baseUrl = 'https://api.x.ai/v1/',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  bool? store,
  String? previousResponseId,
}) {
  final llmConfig = LLMConfig(
    apiKey: apiKey,
    baseUrl: baseUrl,
    model: model,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    providerOptions: {
      'xai.responses': {
        if (store != null) 'store': store,
        if (previousResponseId != null)
          'previousResponseId': previousResponseId,
      },
    },
  );

  return XAIResponsesProvider(llmConfig);
}
