import 'package:llm_dart_core/core/capability.dart';
import 'package:llm_dart_core/core/cancellation.dart';
import 'package:llm_dart_core/core/stream_parts.dart';
import 'package:llm_dart_core/models/chat_models.dart';
import 'package:llm_dart_core/models/tool_models.dart';
import 'package:llm_dart_core/prompt/prompt.dart';

import 'chat.dart';
import 'client.dart';
import 'config.dart';

/// Minimal provider implementation for Anthropic-compatible APIs.
///
/// This mirrors `OpenAICompatibleChatProvider` in `llm_dart_openai_compatible`
/// and exists so compatible providers (e.g. MiniMax) can stay thin and delegate
/// protocol behavior to `llm_dart_anthropic_compatible`.
class AnthropicCompatibleChatProvider
    implements
        ChatCapability,
        PromptChatCapability,
        ChatStreamPartsCapability,
        PromptChatStreamPartsCapability,
        ProviderCapabilities {
  final AnthropicClient _client;
  final AnthropicConfig config;
  final Set<LLMCapability> _supportedCapabilities;

  final String providerName;

  late final AnthropicChat _chat;

  AnthropicCompatibleChatProvider(
    this._client,
    this.config,
    this._supportedCapabilities, {
    this.providerName = 'Anthropic',
  }) {
    _chat = AnthropicChat(_client, config);
  }

  AnthropicClient get client => _client;

  @override
  Set<LLMCapability> get supportedCapabilities => _supportedCapabilities;

  @override
  bool supports(LLMCapability capability) {
    return supportedCapabilities.contains(capability);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancelToken? cancelToken,
  }) {
    return _chat.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancelToken? cancelToken,
  }) {
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
    return _chat.chatStreamParts(messages,
        tools: tools, cancelToken: cancelToken);
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
  Future<List<ChatMessage>?> memoryContents() {
    return _chat.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return _chat.summarizeHistory(messages);
  }
}
