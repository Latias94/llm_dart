part of 'provider_compat.dart';

final class _ElevenLabsUnsupportedChatSupport {
  static const _unsupportedChatError = ProviderError(
    'ElevenLabs does not support chat functionality',
  );

  const _ElevenLabsUnsupportedChatSupport();

  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    throw _unsupportedChatError;
  }

  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  Future<List<ChatMessage>?> memoryContents() async => null;

  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    throw _unsupportedChatError;
  }

  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    yield ErrorEvent(_unsupportedChatError);
  }
}
