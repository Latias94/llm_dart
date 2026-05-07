part of 'google_compat_provider.dart';

typedef _GoogleFallbackChatWithTools = Future<ChatResponse> Function(
  List<ChatMessage> messages,
  List<Tool>? tools, {
  TransportCancellation? cancelToken,
});

typedef _GoogleFallbackChatStream = Stream<ChatStreamEvent> Function(
  List<ChatMessage> messages, {
  List<Tool>? tools,
  TransportCancellation? cancelToken,
});

final class _GoogleCompatChatRouter {
  final LLMConfig originalConfig;
  final LegacyChatCapabilityAdapter adapter;
  final _GoogleFallbackChatWithTools fallbackChatWithTools;
  final _GoogleFallbackChatStream fallbackChatStream;

  const _GoogleCompatChatRouter({
    required this.originalConfig,
    required this.adapter,
    required this.fallbackChatWithTools,
    required this.fallbackChatStream,
  });

  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatChat(
      originalConfig: originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseGoogleChatBridge,
      bridge: () => adapter.chatWithTools(
        messages,
        tools,
        cancelToken: cancelToken,
      ),
      fallback: () => fallbackChatWithTools(
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
      originalConfig: originalConfig,
      messages: messages,
      tools: tools,
      canUseBridge: canUseGoogleChatBridge,
      bridge: () => adapter.chatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
      fallback: () => fallbackChatStream(
        messages,
        tools: tools,
        cancelToken: cancelToken,
      ),
    );
  }
}
