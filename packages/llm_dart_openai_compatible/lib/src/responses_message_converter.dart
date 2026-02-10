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

      case FileMessage(mime: final mime, data: final data):
        final mimeType = mime.mimeType.toLowerCase();

        final contentArray = <Map<String, dynamic>>[];
        if (message.content.isNotEmpty) {
          contentArray.add({
            'type': 'input_text',
            'text': message.content,
          });
        }

        if (mimeType.startsWith('image/')) {
          final base64Data = base64Encode(data);
          contentArray.add({
            'type': 'input_image',
            'image_url': 'data:${mime.mimeType};base64,$base64Data',
          });
          result['content'] = contentArray;
          break;
        }

        if (mimeType == 'application/pdf') {
          final base64Data = base64Encode(data);
          contentArray.add({
            'type': 'input_file',
            'filename': 'document.pdf',
            'file_data': 'data:application/pdf;base64,$base64Data',
          });
          result['content'] = contentArray;
          break;
        }

        throw InvalidRequestError(
          'Unsupported file media type for the Responses API: ${mime.mimeType}',
        );

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

  /// Build the Responses API `input` array from Prompt IR.
  ///
  /// This preserves multi-part message structure without relying on
  /// `Prompt.toChatMessages()` (which emits one message per part).
  ///
  /// Mirrors the behavior of [buildInputMessages]:
  /// - Expands tool results into separate `tool` role messages.
  /// - Collects tool calls on assistant messages into `tool_calls`.
  static List<Map<String, dynamic>> buildInputMessagesFromPrompt(
    Prompt prompt,
  ) {
    final apiMessages = <Map<String, dynamic>>[];

    String? currentRole;
    String? currentName;
    final currentContentParts = <Map<String, dynamic>>[];
    final currentToolCalls = <ToolCall>[];

    void flush() {
      if (currentRole == null) return;
      if (currentContentParts.isEmpty && currentToolCalls.isEmpty) {
        currentRole = null;
        currentName = null;
        return;
      }

      final msg = <String, dynamic>{'role': currentRole};
      if (currentName != null && currentName!.trim().isNotEmpty) {
        msg['name'] = currentName;
      }

      if (currentContentParts.isNotEmpty) {
        if (currentContentParts.length == 1 &&
            currentContentParts.first['type'] == 'input_text' &&
            currentToolCalls.isEmpty) {
          msg['content'] = currentContentParts.first['text'] ?? '';
        } else {
          msg['content'] = List<Map<String, dynamic>>.from(currentContentParts);
        }
      }

      if (currentToolCalls.isNotEmpty) {
        msg['tool_calls'] = currentToolCalls.map((t) => t.toJson()).toList();
      }

      apiMessages.add(msg);

      currentRole = null;
      currentName = null;
      currentContentParts.clear();
      currentToolCalls.clear();
    }

    List<Map<String, dynamic>> toContentParts(PromptPart part) {
      switch (part) {
        case TextPart(:final text):
          if (text.isEmpty) return const [];
          return [
            {
              'type': 'input_text',
              'text': text,
            }
          ];

        case ImagePart(:final mime, :final data, :final text):
          final base64Data = base64Encode(data);
          final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';

          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'input_text', 'text': text});
          }
          parts.add({
            'type': 'input_image',
            'image_url': imageDataUrl,
          });
          return parts;

        case ImageUrlPart(:final url, :final text):
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'input_text', 'text': text});
          }
          parts.add({
            'type': 'input_image',
            'image_url': url,
          });
          return parts;

        case FilePart(:final mime, :final data, :final text):
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'input_text', 'text': text});
          }

          final mimeType = mime.mimeType.toLowerCase();

          if (mimeType.startsWith('image/')) {
            final base64Data = base64Encode(data);
            parts.add({
              'type': 'input_image',
              'image_url': 'data:${mime.mimeType};base64,$base64Data',
            });
            return parts;
          }

          if (mimeType == 'application/pdf') {
            final base64Data = base64Encode(data);
            parts.add({
              'type': 'input_file',
              'filename': 'document.pdf',
              'file_data': 'data:application/pdf;base64,$base64Data',
            });
            return parts;
          }

          throw InvalidRequestError(
            'Unsupported file media type for the Responses API: ${mime.mimeType}',
          );

        case ToolCallPart() || ToolResultPart():
          return const [];
      }
    }

    for (final message in prompt.messages) {
      if (message.role == ChatRole.system) {
        flush();

        final texts = <String>[];
        for (final part in message.parts) {
          if (part case TextPart(:final text)) {
            if (text.trim().isNotEmpty) texts.add(text);
            continue;
          }
          throw const InvalidRequestError(
            'System messages must be plain text for the Responses API.',
          );
        }

        apiMessages.add({
          'role': 'system',
          if (message.name != null && message.name!.trim().isNotEmpty)
            'name': message.name,
          'content': texts.join('\n\n'),
        });
        continue;
      }

      for (final part in message.parts) {
        ChatRole effectiveRole;
        if (part case ToolCallPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else if (part case ToolResultPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else {
          effectiveRole = message.role;
        }

        if (part case ToolCallPart(:final toolCall)) {
          if (effectiveRole != ChatRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          if (currentRole != null && currentRole != 'assistant') {
            flush();
          }
          currentRole ??= 'assistant';
          currentName ??= message.name;
          currentToolCalls.add(toolCall);
          continue;
        }

        if (part case ToolResultPart(:final toolResult)) {
          if (effectiveRole != ChatRole.user) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a user message.',
            );
          }

          flush();
          apiMessages.add({
            'role': 'tool',
            'tool_call_id': toolResult.id,
            'content': toolResult.function.arguments.isNotEmpty
                ? toolResult.function.arguments
                : 'Tool result',
          });
          continue;
        }

        final targetRole =
            effectiveRole == ChatRole.user ? 'user' : 'assistant';
        if (currentRole != null && currentRole != targetRole) {
          flush();
        }
        currentRole ??= targetRole;
        currentName ??= message.name;

        currentContentParts.addAll(toContentParts(part));
      }

      flush();
    }

    return apiMessages;
  }
}
