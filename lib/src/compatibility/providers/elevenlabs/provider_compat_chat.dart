part of 'provider_compat.dart';

mixin _ElevenLabsProviderChat implements ChatCapability {
  _ElevenLabsUnsupportedChatSupport get _chatSupport;

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatSupport.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatSupport.chat(messages, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chatSupport.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chatSupport.summarizeHistory(messages);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    yield* _chatSupport.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }
}
