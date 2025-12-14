import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Helper for converting structured [ModelMessage] instances into
/// OpenAI-style API message payloads.
///
/// This logic is shared by the OpenAI and OpenAI-compatible providers
/// so that:
/// - Multi-part content (text, reasoning, files, URLs) is handled
///   consistently.
/// - Tool calls and tool results are represented in a unified way.
/// - Responses API vs. Chat Completions differences are controlled via
///   the [isResponsesApi] flag.
class OpenAIMessageMapper {
  /// Build API messages from the structured [promptMessages].
  ///
  /// When [isResponsesApi] is true, content parts use the Responses API
  /// shapes (`input_text`, `input_image`, `input_file`). Otherwise the
  /// legacy Chat Completions shapes are used (`text`, `image_url`, `file`).
  static List<Map<String, dynamic>> buildApiMessagesFromPrompt(
    List<ModelMessage> promptMessages, {
    required bool isResponsesApi,
  }) {
    final apiMessages = <Map<String, dynamic>>[];

    for (final message in promptMessages) {
      // Tool results are represented as separate tool messages.
      final hasToolResult =
          message.parts.any((part) => part is ToolResultContentPart);

      if (hasToolResult) {
        _appendToolResultMessagesFromPrompt(message, apiMessages);
      } else {
        apiMessages.add(
          _convertPromptMessage(
            message,
            isResponsesApi: isResponsesApi,
          ),
        );
      }
    }

    return apiMessages;
  }

  static Map<String, dynamic> _convertPromptMessage(
    ModelMessage message, {
    required bool isResponsesApi,
  }) {
    final role = switch (message.role) {
      ChatRole.system => 'system',
      ChatRole.user => 'user',
      ChatRole.assistant => 'assistant',
    };

    // System messages: concatenate text and reasoning content.
    if (role == 'system') {
      final buffer = StringBuffer();
      for (final part in message.parts) {
        if (part is TextContentPart) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(part.text);
        }
      }

      return {
        'role': role,
        'content': buffer.isNotEmpty ? buffer.toString() : '',
      };
    }

    // Assistant messages with optional tool calls.
    if (role == 'assistant') {
      final buffer = StringBuffer();
      final toolCalls = <Map<String, dynamic>>[];

      for (final part in message.parts) {
        if (part is TextContentPart) {
          buffer.write(part.text);
        } else if (part is ReasoningContentPart) {
          buffer.write(part.text);
        } else if (part is ToolCallContentPart) {
          toolCalls.add({
            'id': part.toolCallId ?? 'call_${toolCalls.length}',
            'type': 'function',
            'function': {
              'name': part.toolName,
              'arguments': part.argumentsJson,
            },
          });
        }
      }

      final result = <String, dynamic>{
        'role': 'assistant',
        'content': buffer.toString(),
      };

      if (toolCalls.isNotEmpty) {
        result['tool_calls'] = toolCalls;
      }

      return result;
    }

    // User messages: support pure text and multi-modal (text + files/URLs).
    if (role == 'user') {
      final textParts = message.parts.whereType<TextContentPart>().toList();
      final nonTextParts =
          message.parts.where((p) => p is! TextContentPart).toList();

      // Pure text message
      if (nonTextParts.isEmpty && textParts.length == 1) {
        return {
          'role': 'user',
          'content': textParts.first.text,
        };
      }

      // Multi-part or multi-modal message
      final contentArray = <Map<String, dynamic>>[];

      for (final part in message.parts) {
        if (part is TextContentPart) {
          if (part.text.isEmpty) continue;
          if (isResponsesApi) {
            contentArray.add({'type': 'input_text', 'text': part.text});
          } else {
            contentArray.add({'type': 'text', 'text': part.text});
          }
        } else if (part is ReasoningContentPart) {
          if (part.text.isEmpty) continue;
          if (isResponsesApi) {
            contentArray.add({'type': 'input_text', 'text': part.text});
          } else {
            contentArray.add({'type': 'text', 'text': part.text});
          }
        } else if (part is UrlFileContentPart) {
          final mimeType = part.mime.mimeType;
          final isImage = mimeType.startsWith('image/');

          // OpenAI chat-style inputs only support URL-based images.
          // For non-image URLs, fall back to a textual hint to avoid
          // sending invalid multi-modal payloads.
          if (!isImage) {
            final text = '[Unsupported URL file type for OpenAI: $mimeType. '
                'Download and pass bytes via FileContentPart instead: ${part.url}]';
            if (isResponsesApi) {
              contentArray.add({'type': 'input_text', 'text': text});
            } else {
              contentArray.add({'type': 'text', 'text': text});
            }
            continue;
          }

          if (isResponsesApi) {
            contentArray.add({
              'type': 'input_image',
              'image_url': part.url,
            });
          } else {
            contentArray.add({
              'type': 'image_url',
              'image_url': {'url': part.url},
            });
          }
        } else if (part is FileContentPart) {
          _appendFilePartForPrompt(part, contentArray, isResponsesApi);
        }
      }

      return {
        'role': 'user',
        'content': contentArray,
      };
    }

    // Fallback (should not reach here)
    return {
      'role': role,
      'content': '',
    };
  }

  static void _appendFilePartForPrompt(
    FileContentPart part,
    List<Map<String, dynamic>> contentArray,
    bool isResponsesApi,
  ) {
    final mime = part.mime;
    final data = part.data;
    final base64Data = base64Encode(data);

    if (mime.mimeType.startsWith('image/')) {
      final imageDataUrl = 'data:${mime.mimeType};base64,$base64Data';
      if (isResponsesApi) {
        contentArray.add({
          'type': 'input_image',
          'image_url': imageDataUrl,
        });
      } else {
        contentArray.add({
          'type': 'image_url',
          'image_url': {'url': imageDataUrl},
        });
      }
    } else {
      if (isResponsesApi) {
        contentArray.add({
          'type': 'input_file',
          'file_data': base64Data,
        });
      } else {
        contentArray.add({
          'type': 'file',
          'file': {'file_data': base64Data},
        });
      }
    }
  }

  static void _appendToolResultMessagesFromPrompt(
    ModelMessage message,
    List<Map<String, dynamic>> apiMessages,
  ) {
    final fallbackText = message.parts
        .whereType<TextContentPart>()
        .map((p) => p.text)
        .join('\n');

    for (final part in message.parts) {
      if (part is! ToolResultContentPart) continue;

      String content;
      final payload = part.payload;
      if (payload is ToolResultTextPayload) {
        content = payload.value.isNotEmpty ? payload.value : fallbackText;
      } else if (payload is ToolResultJsonPayload) {
        content = jsonEncode(payload.value);
      } else if (payload is ToolResultErrorPayload) {
        content = payload.message;
      } else if (payload is ToolResultContentPayload) {
        final texts = <String>[];
        for (final nested in payload.parts) {
          if (nested is TextContentPart) {
            texts.add(nested.text);
          }
        }
        content = texts.join('\n');
      } else {
        content = fallbackText.isNotEmpty ? fallbackText : 'Tool result';
      }

      apiMessages.add({
        'role': 'tool',
        'tool_call_id': part.toolCallId,
        'content': content,
      });
    }
  }
}
