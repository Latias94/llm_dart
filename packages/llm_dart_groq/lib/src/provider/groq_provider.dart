// Groq provider implementation built on ChatMessage-based chat
// capabilities from the OpenAI-compatible layer. ChatMessage is
// used intentionally here for compatibility with llm_dart_core.
// ignore_for_file: deprecated_member_use

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';

import '../config/groq_config.dart';

/// Groq provider implementation built on top of the OpenAI-compatible chat.
class GroqProvider implements ChatCapability, ProviderCapabilities {
  final GroqConfig config;
  late final OpenAICompatibleClient _client;
  late final OpenAICompatibleChat _chat;

  GroqProvider(this.config) {
    _client = OpenAICompatibleClient(config);
    _chat = OpenAICompatibleChat(_client, config);
  }

  String get providerName => 'Groq';

  // ===== ChatCapability =====

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
  Future<List<ChatMessage>?> memoryContents() {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return _chat.summarizeHistory(messages);
  }

  // ===== ProviderCapabilities =====

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        if (config.supportsToolCalling) LLMCapability.toolCalling,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  /// Model family information.
  String get modelFamily => config.modelFamily;

  /// Whether this provider is optimized for speed.
  bool get isSpeedOptimized => config.isSpeedOptimized;
}
