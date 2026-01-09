import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Convert `ChatMessage` into the Responses API `input` shape.
///
/// This lives in `llm_dart_openai_compatible` so both the OpenAI and Azure
/// OpenAI provider packages can reuse the same request mapping without
/// provider-to-provider dependencies.
class OpenAIResponsesMessageConverter {
  static Map<String, dynamic> convertMessage(ChatMessage message) {
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

        final contentArray = <Map<String, dynamic>>[];
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'input_text',
            'text': message.content,
          });
        }
        contentArray.add({
          'type': 'input_image',
          'image_url': imageDataUrl,
        });

        result['content'] = contentArray;
        break;

      case ImageUrlMessage(url: final url):
        final contentArray = <Map<String, dynamic>>[];
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'input_text',
            'text': message.content,
          });
        }
        contentArray.add({
          'type': 'input_image',
          'image_url': url,
        });

        result['content'] = contentArray;
        break;

      case FileMessage(data: final data):
        final base64Data = base64Encode(data);

        final contentArray = <Map<String, dynamic>>[];
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'input_text',
            'text': message.content,
          });
        }
        contentArray.add({
          'type': 'input_file',
          'file_data': base64Data,
        });

        result['content'] = contentArray;
        break;

      case ToolUseMessage(toolCalls: final toolCalls):
        result['tool_calls'] = toolCalls.map((tc) => tc.toJson()).toList();
        break;

      case ToolResultMessage(results: final results):
        result['content'] =
            message.content.isNotEmpty ? message.content : 'Tool result';
        result['tool_call_id'] = results.isNotEmpty ? results.first.id : null;
        break;
    }

    return result;
  }

  /// Build the Responses API `input` array from a list of messages.
  ///
  /// Mirrors the Chat Completions conversion behavior:
  /// - Expands `tool_result` blocks into separate `tool` role messages.
  static List<Map<String, dynamic>> buildInputMessages(
    List<ChatMessage> messages,
  ) {
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
}
