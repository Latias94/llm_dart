import 'package:llm_dart_anthropic_compatible/client.dart';
import 'package:llm_dart_anthropic_compatible/config.dart';
import 'package:llm_dart_anthropic_compatible/dio_strategy.dart';
import 'package:llm_dart_anthropic_compatible/provider.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// MiniMax provider implementation (Anthropic-compatible).
///
/// This provider is intentionally thin and delegates protocol behavior to
/// `llm_dart_anthropic_compatible`.
class MinimaxProvider
    implements
        ChatCapability,
        PromptChatCapability,
        ChatStreamPartsCapability,
        PromptChatStreamPartsCapability,
        ProviderCapabilities {
  static const Set<LLMCapability> _supportedCapabilities = {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
  };

  final AnthropicConfig config;
  final AnthropicCompatibleChatProvider _delegate;

  MinimaxProvider(this.config)
      : _delegate = AnthropicCompatibleChatProvider(
          AnthropicClient(
            config,
            strategy: AnthropicDioStrategy(providerName: 'MiniMax'),
          ),
          config,
          _supportedCapabilities,
          providerName: 'MiniMax',
        );

  String get providerName => 'MiniMax';

  @override
  Set<LLMCapability> get supportedCapabilities =>
      _delegate.supportedCapabilities;

  @override
  bool supports(LLMCapability capability) => _delegate.supports(capability);

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) =>
      _delegate.chat(messages, cancelToken: cancelToken);

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) =>
      _delegate.chatWithTools(messages, tools, cancelToken: cancelToken);

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      _delegate.chatStream(messages, tools: tools, cancelToken: cancelToken);

  @override
  Stream<LLMStreamPart> chatStreamParts(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      _delegate.chatStreamParts(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      );

  @override
  Future<ChatResponse> chatPrompt(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      _delegate.chatPrompt(prompt, tools: tools, cancelToken: cancelToken);

  @override
  Stream<ChatStreamEvent> chatPromptStream(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      _delegate.chatPromptStream(prompt,
          tools: tools, cancelToken: cancelToken);

  @override
  Stream<LLMStreamPart> chatPromptStreamParts(
    Prompt prompt, {
    List<Tool>? tools,
    CancelToken? cancelToken,
  }) =>
      _delegate.chatPromptStreamParts(
        prompt,
        tools: tools,
        cancelToken: cancelToken,
      );

  @override
  Future<List<ChatMessage>?> memoryContents() => _delegate.memoryContents();

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      _delegate.summarizeHistory(messages);
}
