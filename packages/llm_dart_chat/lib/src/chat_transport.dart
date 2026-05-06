import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'chat_request_options.dart';

enum ChatTransportTrigger {
  sendMessage,
  regenerate,
  toolOutput,
  toolApproval,
}

final class ChatTransportRequest {
  final String chatId;
  final ChatTransportTrigger trigger;
  final List<PromptMessage> prompt;
  final ChatRequestOptions options;

  ChatTransportRequest({
    required this.chatId,
    this.trigger = ChatTransportTrigger.sendMessage,
    required List<PromptMessage> prompt,
    this.options = const ChatRequestOptions(),
  }) : prompt = List.unmodifiable(prompt);
}

abstract interface class ChatTransport {
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request);

  Stream<ChatUiStreamChunk>? reconnect(String chatId);
}
