import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat_transport.dart';

final class DirectChatTransport implements ChatTransport {
  final LanguageModel model;

  const DirectChatTransport({
    required this.model,
  });

  @override
  Stream<ChatTransportChunk> sendMessages(ChatTransportRequest request) {
    return model
        .stream(
          GenerateTextRequest(
            prompt: request.prompt,
            options: request.options.generateOptions,
            callOptions: request.options.callOptions,
          ),
        )
        .map<ChatTransportChunk>((event) => ChatTransportEventChunk(event));
  }

  @override
  Stream<ChatTransportChunk>? reconnect(String chatId) => null;
}
