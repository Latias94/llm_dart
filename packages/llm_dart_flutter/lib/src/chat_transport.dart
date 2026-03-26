import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat_request_options.dart';

final class ChatTransportRequest {
  final String chatId;
  final List<PromptMessage> prompt;
  final ChatRequestOptions options;

  ChatTransportRequest({
    required this.chatId,
    required List<PromptMessage> prompt,
    this.options = const ChatRequestOptions(),
  }) : prompt = List.unmodifiable(prompt);
}

abstract interface class ChatTransport {
  Stream<TextStreamEvent> sendMessages(ChatTransportRequest request);

  Stream<TextStreamEvent>? reconnect(String chatId);
}
