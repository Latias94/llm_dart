import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat_transport.dart';

final class DirectChatTransport implements ChatTransport {
  final LanguageModel model;

  const DirectChatTransport({
    required this.model,
  });

  @override
  Stream<TextStreamEvent> sendMessages(ChatTransportRequest request) {
    return model.stream(
      GenerateTextRequest(
        prompt: request.prompt,
        options: request.options.generateOptions,
        providerOptions: request.options.providerOptions,
      ),
    );
  }

  @override
  Stream<TextStreamEvent>? reconnect(String chatId) => null;
}
