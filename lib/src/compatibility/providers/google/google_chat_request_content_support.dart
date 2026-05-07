part of 'google_chat_request_builder.dart';

final class _GoogleChatRequestContentSupport {
  final GoogleConfig config;
  final GoogleChatMessageCodec messageCodec;

  _GoogleChatRequestContentSupport({
    required this.config,
    required this.messageCodec,
  });

  List<Map<String, dynamic>> buildContents(List<ChatMessage> messages) {
    final contents = <Map<String, dynamic>>[];

    if (config.systemPrompt != null) {
      contents.add({
        'role': 'user',
        'parts': [
          {'text': config.systemPrompt},
        ],
      });
    }

    for (final message in messages) {
      if (message.role == ChatRole.system) continue;
      contents.add(messageCodec.convertMessage(message));
    }

    return contents;
  }
}
