part of 'shell_support.dart';

final class _OllamaCompatChatRouter {
  final LLMConfig compatConfig;
  final LegacyChatCapabilityAdapter compatChat;
  final OllamaChat chatFallback;

  const _OllamaCompatChatRouter({
    required this.compatConfig,
    required this.compatChat,
    required this.chatFallback,
  });

  bool canUseChatBridge(List<ChatMessage> messages) {
    if (messages.any((message) => message.name != null)) {
      return false;
    }

    final hasConfigSystemPrompt = compatConfig.systemPrompt != null &&
        compatConfig.systemPrompt!.isNotEmpty;
    if (hasConfigSystemPrompt &&
        messages.any((message) => message.role == ChatRole.system)) {
      return false;
    }

    return true;
  }

  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return executeCompatChat(
      originalConfig: compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: (config, messages, tools) => canUseChatBridge(messages),
      bridge: () =>
          compatChat.chatWithTools(messages, tools, cancelToken: cancelToken),
      fallback: () => chatFallback.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
    );
  }

  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChatStream(
      originalConfig: compatConfig,
      messages: messages,
      tools: tools,
      canUseBridge: (config, messages, tools) => canUseChatBridge(messages),
      bridge: () => compatChat.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => chatFallback.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}
