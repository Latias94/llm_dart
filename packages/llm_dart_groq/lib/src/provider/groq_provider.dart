// Groq provider implementation built on the OpenAI-compatible chat layer.

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/protocol.dart';

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
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _chat.chat(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
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
