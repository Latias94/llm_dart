import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_transport.dart';

final class DirectChatTransport implements ChatTransport {
  final LanguageModel model;

  const DirectChatTransport({
    required this.model,
  });

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) {
    return model
        .doStream(
          GenerateTextRequest(
            prompt: request.prompt,
            options: request.options.generateOptions,
            callOptions: request.options.callOptions,
          ),
        )
        .map<ChatUiStreamChunk>((event) => ChatUiEventChunk(event));
  }

  @override
  Stream<ChatUiStreamChunk>? reconnect(String chatId) => null;
}
