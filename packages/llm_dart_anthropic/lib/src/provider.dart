import 'package:llm_dart_anthropic_compatible/chat.dart';
import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Anthropic provider implementation
///
/// This provider implements multiple capability interfaces following the
/// modular architecture pattern. It supports:
/// - ChatCapability: Core chat functionality
///
/// **API Documentation:**
/// - Messages API: https://platform.claude.com/docs/en/api/messages
/// - Models API: https://platform.claude.com/docs/en/api/models/list
/// - Token Counting: https://platform.claude.com/docs/en/api/messages/count-tokens
/// - Extended Thinking: https://platform.claude.com/docs/en/build-with-claude/extended-thinking
///
/// This provider delegates to specialized capability modules for different
/// functionalities, maintaining clean separation of concerns.
class AnthropicProvider
    implements
        ChatCapability,
        PromptChatCapability,
        ChatStreamPartsCapability,
        PromptChatStreamPartsCapability,
        ProviderCapabilities {
  final AnthropicClient _client;
  final AnthropicConfig config;

  // Capability modules
  late final AnthropicChat _chat;

  AnthropicProvider(this.config)
      : _client = AnthropicClient(config, strategy: AnthropicDioStrategy()) {
    // Validate configuration on initialization
    final validationError = config.validateThinkingConfig();
    if (validationError != null) {
      _client.logger
          .warning('Anthropic configuration warning: $validationError');
    }

    // Initialize capability modules
    _chat = AnthropicChat(_client, config);
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
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPrompt(prompt, tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> chatPromptStream(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStream(prompt,
        tools: tools, cancelToken: cancelToken);
  }

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) {
    return _chat.chatPromptStreamParts(
      prompt,
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

  /// Get provider name
  String get providerName => 'Anthropic';

  // ========== ProviderCapabilities ==========

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.toolCalling,
        if (config.supportsVision) LLMCapability.vision,
        if (config.supportsReasoning) LLMCapability.reasoning,
      };

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }
}
