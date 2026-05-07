part of 'google_chat_message_codec.dart';

final class _GoogleChatMessageContentSupport {
  final GoogleClient client;
  final GoogleConfig config;

  _GoogleChatMessageContentSupport({
    required this.client,
    required this.config,
  });

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
        final supportedFormats = [
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp',
        ];
        if (!supportedFormats.contains(mime.mimeType)) {
          parts.add({
            'text':
                '[Unsupported image format: ${mime.mimeType}. Supported formats: ${supportedFormats.join(', ')}]',
          });
        } else {
          parts.add({
            'inlineData': {
              'mimeType': mime.mimeType,
              'data': base64Encode(data),
            },
          });
        }
        break;
      case FileMessage(mime: final mime, data: final data):
        if (data.length > config.maxInlineDataSize) {
          parts.add({
            'text':
                '[File too large: ${data.length} bytes. Maximum size: ${config.maxInlineDataSize} bytes]',
          });
        } else if (mime.isDocument || mime.isAudio || mime.isVideo) {
          parts.add({
            'inlineData': {
              'mimeType': mime.mimeType,
              'data': base64Encode(data),
            },
          });
        } else {
          parts.add({
            'text':
                '[File type ${mime.description} (${mime.mimeType}) may not be supported by Google AI]',
          });
        }
        break;
      case ImageUrlMessage(url: final url):
        parts.add({
          'text':
              '[Image URL not supported by Google. Please upload the image directly: $url]',
        });
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        for (final toolCall in toolCalls) {
          try {
            final args = jsonDecode(toolCall.function.arguments);
            parts.add({
              'functionCall': {
                'name': toolCall.function.name,
                'args': args,
              },
            });
          } catch (e) {
            client.logger.warning(
              'Failed to parse tool call arguments: '
              '${toolCall.function.arguments}, error: $e',
            );
            parts.add({
              'text':
                  '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
            });
          }
        }
        break;
      case ToolResultMessage(results: final results):
        for (final result in results) {
          parts.add({
            'functionResponse': {
              'name': result.function.name,
              'response': {
                'name': result.function.name,
                'content': jsonDecode(result.function.arguments),
              },
            },
          });
        }
        break;
    }

    return {
      'role': role,
      'parts': parts,
    };
  }
}
