import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_transport.dart';

final class DirectChatTransport implements ChatTransport {
  final LanguageModel model;

  const DirectChatTransport({
    required this.model,
  });

  @override
  Stream<ChatUiStreamChunk> sendMessages(ChatTransportRequest request) {
    return projectTextStreamEventStream(
      streamText(
        model: model,
        prompt: request.prompt,
        options: request.options.generateOptions,
        callOptions: request.options.callOptions,
      ),
      messageMetadata: request.options.metadata,
    );
  }

  @override
  Stream<ChatUiStreamChunk>? reconnect(String chatId) => null;
}
