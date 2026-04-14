import 'dart:convert';

import '../../../../models/chat_models.dart';

/// Encodes legacy compatibility chat messages into OpenAI-family request
/// payloads while preserving the existing public `OpenAIClient` helper API.
class OpenAIClientMessageCodec {
  final bool usesResponsesApi;

  OpenAIClientMessageCodec({
    required this.usesResponsesApi,
  });

  Map<String, dynamic> convertMessage(ChatMessage message) {
    final result = <String, dynamic>{'role': message.role.name};

    if (message.name != null) {
      result['name'] = message.name;
    }

    switch (message.messageType) {
      case TextMessage():
        result['content'] = message.content;
        break;
      case ImageMessage(mime: final mime, data: final data):
        final base64Data = base64Encode(data);
        final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';
        result['content'] = _buildInlineAttachmentContent(
          text: message.content,
          attachment: usesResponsesApi
              ? {
                  'type': 'input_image',
                  'image_url': imageDataUrl,
                }
              : {
                  'type': 'image_url',
                  'image_url': {'url': imageDataUrl},
                },
        );
        break;

      case ImageUrlMessage(url: final url):
        result['content'] = _buildInlineAttachmentContent(
          text: message.content,
          attachment: usesResponsesApi
              ? {
                  'type': 'input_image',
                  'image_url': url,
                }
              : {
                  'type': 'image_url',
                  'image_url': {'url': url},
                },
        );
        break;

      case FileMessage(data: final data):
        final base64Data = base64Encode(data);
        result['content'] = _buildInlineAttachmentContent(
          text: message.content,
          attachment: usesResponsesApi
              ? {
                  'type': 'input_file',
                  'file_data': base64Data,
                }
              : {
                  'type': 'file',
                  'file': {
                    'file_data': base64Data,
                  },
                },
        );
        break;

      case ToolUseMessage(toolCalls: final toolCalls):
        result['tool_calls'] =
            toolCalls.map((toolCall) => toolCall.toJson()).toList();
        break;
      case ToolResultMessage(results: final results):
        result['content'] =
            message.content.isNotEmpty ? message.content : 'Tool result';
        result['tool_call_id'] = results.isNotEmpty ? results.first.id : null;
        break;
    }

    return result;
  }

  List<Map<String, dynamic>> buildApiMessages(List<ChatMessage> messages) {
    final apiMessages = <Map<String, dynamic>>[];

    for (final message in messages) {
      if (message.messageType is ToolResultMessage) {
        final toolResults = (message.messageType as ToolResultMessage).results;
        for (final result in toolResults) {
          apiMessages.add({
            'role': 'tool',
            'tool_call_id': result.id,
            'content': message.content.isNotEmpty
                ? message.content
                : (result.function.arguments.isNotEmpty
                    ? result.function.arguments
                    : 'Tool result'),
          });
        }
        continue;
      }

      apiMessages.add(convertMessage(message));
    }

    return apiMessages;
  }

  List<Map<String, dynamic>> _buildInlineAttachmentContent({
    required String text,
    required Map<String, dynamic> attachment,
  }) {
    final content = <Map<String, dynamic>>[];

    if (text.isNotEmpty) {
      content.add(_buildTextContent(text));
    }

    content.add(attachment);
    return content;
  }

  Map<String, dynamic> _buildTextContent(String text) {
    return usesResponsesApi
        ? {
            'type': 'input_text',
            'text': text,
          }
        : {
            'type': 'text',
            'text': text,
          };
  }
}
