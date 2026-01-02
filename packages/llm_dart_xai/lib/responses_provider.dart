import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'responses.dart';

/// xAI provider using the Responses API (`POST /v1/responses`).
///
/// Registry id: `xai.responses` (Vercel-style).
class XAIResponsesProvider
    implements ChatCapability, ChatStreamPartsCapability, ProviderCapabilities {
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
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return _responses.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
    return _responses.chatWithTools(messages, tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _responses.chatStream(messages,
        tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _responses.chatStreamParts(
      messages,
      tools: tools,
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
