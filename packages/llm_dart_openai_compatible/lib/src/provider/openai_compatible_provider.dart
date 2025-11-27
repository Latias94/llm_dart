import 'package:llm_dart_core/llm_dart_core.dart';

import '../chat/openai_compatible_chat.dart';
import '../client/openai_compatible_client.dart';
import '../config/openai_compatible_config.dart';

/// Generic provider implementation for OpenAI-compatible vendors.
///
/// This wraps [OpenAICompatibleChat] and exposes it as a [ChatCapability]
/// with basic [ProviderCapabilities] metadata.
class OpenAICompatibleProvider implements ChatCapability, ProviderCapabilities {
  final OpenAICompatibleChat _chat;
  final OpenAICompatibleConfig config;

  OpenAICompatibleProvider(this.config)
      : _chat = OpenAICompatibleChat(OpenAICompatibleClient(config), config);

  String get providerName => config.providerId;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chat(
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatWithTools(
      messages,
      tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chatStream(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() => _chat.memoryContents();

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      _chat.summarizeHistory(messages);

  @override
  Set<LLMCapability> get supportedCapabilities {
    final capabilities = <LLMCapability>{
      LLMCapability.chat,
      LLMCapability.streaming,
    };

    if (config.tools != null && config.tools!.isNotEmpty) {
      capabilities.add(LLMCapability.toolCalling);
    }

    if (config.reasoningEffort != null) {
      capabilities.add(LLMCapability.reasoning);
    }

    return capabilities;
  }

  @override
  bool supports(LLMCapability capability) =>
      supportedCapabilities.contains(capability);
}
