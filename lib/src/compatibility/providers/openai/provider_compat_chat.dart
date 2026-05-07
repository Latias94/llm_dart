part of 'provider_compat.dart';

mixin OpenAIProviderChatMixin implements ChatCapability {
  OpenAIProviderChatFacade get _chatFacade;

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatFacade.chat(
      messages,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    return _chatFacade.chatWithTools(
      messages,
      tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) {
    return _chatFacade.chatStream(
      messages,
      tools: tools,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async {
    return _chatFacade.memoryContents();
  }

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    return _chatFacade.summarizeHistory(messages);
  }
}
