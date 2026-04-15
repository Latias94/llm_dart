import 'package:llm_dart_core/model.dart';
import 'package:llm_dart_core/ui.dart';

import 'chat_transport.dart';

final class DirectChatTransport implements ChatTransport {
  final LanguageModel model;

  const DirectChatTransport({
    required this.model,
  });

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) {
    return model
        .stream(
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
