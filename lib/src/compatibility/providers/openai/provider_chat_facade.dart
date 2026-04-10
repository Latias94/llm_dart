import '../../../../core/capability.dart';
import '../../../../core/config.dart';
import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/openai/config.dart';
import '../../chat_route_compatibility.dart';
import '../../legacy_chat_adapter.dart';
import '../compat_provider_support.dart';
import 'bridge_support.dart';
import 'chat.dart';
import 'responses.dart';

/// Local chat-routing facade for the root OpenAI compatibility provider.
///
/// This keeps bridge routing, bridge fallback, and Responses-vs-chat selection
/// out of `OpenAIProvider` itself so the public provider shell can stay focused
/// on capability composition.
final class OpenAIProviderChatFacade {
  final OpenAIChat _chat;
  final OpenAIResponses? _responses;
  final LLMConfig? _chatBridgeConfig;
  final LegacyChatCapabilityAdapter? _chatBridge;

  factory OpenAIProviderChatFacade({
    required OpenAIConfig config,
    required OpenAIChat chat,
    required OpenAIResponses? responses,
  }) {
    final chatBridgeConfig = supportsRootOpenAIChatBridgeHost(config)
        ? buildRootOpenAIChatBridgeConfig(config)
        : null;

    return OpenAIProviderChatFacade._(
      chat: chat,
      responses: responses,
      chatBridgeConfig: chatBridgeConfig,
      chatBridge: chatBridgeConfig == null
          ? null
          : buildCompatOpenAIChatBridge(
              legacyConfig: config,
              bridgeConfig: chatBridgeConfig,
            ),
    );
  }

  const OpenAIProviderChatFacade._({
    required OpenAIChat chat,
    required OpenAIResponses? responses,
    required LLMConfig? chatBridgeConfig,
    required LegacyChatCapabilityAdapter? chatBridge,
  })  : _chat = chat,
        _responses = responses,
        _chatBridgeConfig = chatBridgeConfig,
        _chatBridge = chatBridge;

  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) {
    return chatWithTools(
      messages,
      null,
      cancelToken: cancelToken,
    );
  }

  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    final chatBridge = _chatBridge;
    final chatBridgeConfig = _chatBridgeConfig;
    if (chatBridge != null && chatBridgeConfig != null) {
      return executeCompatChat(
        originalConfig: chatBridgeConfig,
        messages: messages,
        tools: tools,
        canUseBridge: canUseOpenAIChatBridge,
        bridge: () => chatBridge.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        ),
        fallback: () => _fallbackChat.chatWithTools(
          messages,
          tools,
          cancelToken: cancelToken,
        ),
      );
    }

    return _fallbackChat.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    final chatBridge = _chatBridge;
    final chatBridgeConfig = _chatBridgeConfig;
    if (chatBridge != null && chatBridgeConfig != null) {
      return executeCompatChatStream(
        originalConfig: chatBridgeConfig,
        messages: messages,
        tools: tools,
        canUseBridge: canUseOpenAIChatBridge,
        bridge: () => chatBridge.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        ),
        fallback: () => _fallbackChat.chatStream(
          messages,
          tools: tools,
          cancelToken: cancelToken,
        ),
      );
    }

    return _fallbackChat.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  Future<List<ChatMessage>?> memoryContents() {
    return _fallbackChat.memoryContents();
  }

  Future<String> summarizeHistory(List<ChatMessage> messages) {
    return _fallbackChat.summarizeHistory(messages);
  }

  ChatCapability get _fallbackChat => _responses ?? _chat;
}

bool supportsRootOpenAIChatBridgeHost(OpenAIConfig config) {
  // The root-provider modern bridge is intentionally narrowed to official
  // OpenAI-hosted requests. Deprecated OpenAI-compatible preset helpers stay on
  // the compatibility fallback path until or unless the project chooses a
  // separate provider-owned migration for them.
  final uri = Uri.tryParse(config.baseUrl);
  return uri?.host.toLowerCase() == 'api.openai.com';
}
