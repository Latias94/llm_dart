part of 'google_chat_message_codec.dart';

final class _GoogleChatMessageContentSupport {
  final GoogleClient client;
  final GoogleConfig config;
  static const _mediaSupport = _GoogleChatMessageMediaSupport();
  late final _GoogleChatToolSupport _toolSupport;

  _GoogleChatMessageContentSupport({
    required this.client,
    required this.config,
  }) {
    _toolSupport = _GoogleChatToolSupport(client: client);
  }

  Map<String, dynamic> convertMessage(ChatMessage message) {
    final parts = <Map<String, dynamic>>[];

    final role = switch (message.messageType) {
      ToolResultMessage() => 'function',
      _ => message.role == ChatRole.user ? 'user' : 'model',
    };

    switch (message.messageType) {
      case TextMessage():
        parts.add({'text': message.content});
        break;
      case ImageMessage(mime: final mime, data: final data):
        parts.add(_mediaSupport.convertImage(mime, data));
        break;
      case FileMessage(mime: final mime, data: final data):
        parts.add(
          _mediaSupport.convertFile(
            mime,
            data,
            maxInlineDataSize: config.maxInlineDataSize,
          ),
        );
        break;
      case ImageUrlMessage(url: final url):
        parts.add(_mediaSupport.convertImageUrl(url));
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        parts.addAll(_toolSupport.convertToolUse(toolCalls));
        break;
      case ToolResultMessage(results: final results):
        parts.addAll(_toolSupport.convertToolResult(results));
        break;
    }

    return {
      'role': role,
      'parts': parts,
    };
  }
}
