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

sealed class ChatTransportChunk {
  const ChatTransportChunk();
}

final class ChatTransportEventChunk extends ChatTransportChunk {
  final TextStreamEvent event;

  const ChatTransportEventChunk(this.event);
}

final class ChatTransportDataPartChunk extends ChatTransportChunk {
  final DataUiPart<Object?> part;

  const ChatTransportDataPartChunk(this.part);
}

abstract interface class ChatTransport {
  Stream<ChatTransportChunk> sendMessages(ChatTransportRequest request);

  Stream<ChatTransportChunk>? reconnect(String chatId);
}
