import 'dart:convert';

import '../../../../models/chat_models.dart';
import 'request_builder_message_extension_support.dart';
import 'request_builder_message_tool_support.dart';

final class AnthropicMessageContentSupport {
  const AnthropicMessageContentSupport();

  static const _extensionSupport = AnthropicMessageExtensionSupport();
  static const _toolSupport = AnthropicMessageToolSupport();

  Map<String, dynamic> convert(ChatMessage message) {
    return {
      'role': message.role.name,
      'content': _convertContent(message),
    };
  }

  List<Map<String, dynamic>> _convertContent(ChatMessage message) {
    final extensionContent = _extensionSupport.extractContent(message);

    if (extensionContent.hasExtension) {
      final content = <Map<String, dynamic>>[
        ...extensionContent.contentBlocks,
      ];

      if (message.content.isNotEmpty) {
        content.add(_textBlock(
          message.content,
          cacheControl: extensionContent.cacheControl,
        ));
      }

      return content;
    }

    switch (message.messageType) {
      case TextMessage():
        return [_textBlock(message.content)];
      case ImageMessage(mime: final mime, data: final data):
        return [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mime.mimeType,
              'data': base64Encode(data),
            },
          },
        ];
      case ImageUrlMessage(url: final url):
        return [
          {
            'type': 'image',
            'source': {
              'type': 'url',
              'url': url,
            },
          },
        ];
      case ToolUseMessage(toolCalls: final toolCalls):
        return _toolSupport.convertToolUseBlocks(toolCalls);
      case ToolResultMessage(results: final results):
        return _toolSupport.convertToolResultBlocks(results);
      default:
        return [_textBlock(message.content)];
    }
  }

  Map<String, dynamic> _textBlock(
    String text, {
    Map<String, dynamic>? cacheControl,
  }) {
    return {
      'type': 'text',
      'text': text,
      if (cacheControl != null) 'cache_control': cacheControl,
    };
  }
}
