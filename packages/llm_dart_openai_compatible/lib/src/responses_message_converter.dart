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
    Prompt prompt, {
    // OpenAI Responses API `store` defaults to true. This controls whether the
    // model may emit stored items and whether tool approval responses should be
    // referenced via `item_reference`.
    bool store = true,
  }) {
    final apiMessages = <Map<String, dynamic>>[];
    final processedApprovalIds = <String>{};

    String? currentRole;
    String? currentName;
    final currentContentParts = <Map<String, dynamic>>[];

    void flush() {
      if (currentRole == null) return;
      if (currentContentParts.isEmpty) {
        currentRole = null;
        currentName = null;
        return;
      }

      final msg = <String, dynamic>{'role': currentRole};
      if (currentName != null && currentName!.trim().isNotEmpty) {
        msg['name'] = currentName;
      }

      if (currentContentParts.isNotEmpty) {
        msg['content'] = List<Map<String, dynamic>>.from(currentContentParts);
      }

      apiMessages.add(msg);

      currentRole = null;
      currentName = null;
      currentContentParts.clear();
    }

    List<Map<String, dynamic>> toContentParts(
      PromptPart part, {
      required String role,
    }) {
      switch (part) {
        case TextPart(:final text):
          if (text.isEmpty) return const [];
          return [
            {
              'type': role == 'assistant' ? 'output_text' : 'input_text',
              'text': text,
            }
          ];

        case ImagePart(:final mime, :final data, :final text):
          if (role == 'assistant') {
            throw const InvalidRequestError(
              'Assistant messages cannot contain inline images for the Responses API.',
            );
          }
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
          if (role == 'assistant') {
            throw const InvalidRequestError(
              'Assistant messages cannot contain image URLs for the Responses API.',
            );
          }
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
          if (role == 'assistant') {
            throw const InvalidRequestError(
              'Assistant messages cannot contain files for the Responses API.',
            );
          }
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

        case FileUrlPart(:final mime, :final url, :final text):
          if (role == 'assistant') {
            throw const InvalidRequestError(
              'Assistant messages cannot contain file URLs for the Responses API.',
            );
          }
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'input_text', 'text': text});
          }

          final mimeType = mime.mimeType.toLowerCase();
          final trimmed = url.trim();

          if (mimeType.startsWith('image/')) {
            parts.add({
              'type': 'input_image',
              'image_url': trimmed,
            });
            return parts;
          }

          if (mimeType == 'application/pdf') {
            parts.add({
              'type': 'input_file',
              'file_url': trimmed,
            });
            return parts;
          }

          throw InvalidRequestError(
            'Unsupported file URL media type for the Responses API: ${mime.mimeType}',
          );

        case FileIdPart(:final mime, :final id, :final text):
          if (role == 'assistant') {
            throw const InvalidRequestError(
              'Assistant messages cannot contain file ids for the Responses API.',
            );
          }
          final parts = <Map<String, dynamic>>[];
          if (text != null && text.trim().isNotEmpty) {
            parts.add({'type': 'input_text', 'text': text});
          }

          final mimeType = mime.mimeType.toLowerCase();
          final trimmed = id.trim();
          if (trimmed.isEmpty) {
            throw const InvalidRequestError('File id cannot be empty.');
          }

          if (mimeType.startsWith('image/')) {
            parts.add({
              'type': 'input_image',
              'file_id': trimmed,
            });
            return parts;
          }

          if (mimeType == 'application/pdf') {
            parts.add({
              'type': 'input_file',
              'file_id': trimmed,
            });
            return parts;
          }

          throw InvalidRequestError(
            'Unsupported file id media type for the Responses API: ${mime.mimeType}',
          );

        case ToolCallPart() ||
              ToolResultPart() ||
              ToolApprovalResponsePart() ||
              ToolApprovalRequestPart():
          return const [];
      }
    }

    String? openAiItemIdFromProviderOptions(ProviderOptions providerOptions) {
      final openai = providerOptions['openai'];
      if (openai == null) return null;
      final itemId = openai['itemId'];
      if (itemId is! String) return null;
      final trimmed = itemId.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    ProviderOptions mergeProviderOptions(
      ProviderOptions base,
      ProviderOptions override,
    ) {
      if (base.isEmpty) return override;
      if (override.isEmpty) return base;

      final merged = <String, Map<String, dynamic>>{...base};
      for (final entry in override.entries) {
        final existing = merged[entry.key];
        merged[entry.key] = {...?existing, ...entry.value};
      }
      return merged;
    }

    Object functionCallOutputValueForToolResult(
      ToolResultOutput output,
      ProviderOptions mergedProviderOptions,
    ) {
      final openaiProviderOptions = mergedProviderOptions['openai'];

      // AI SDK parity: skip execution-denied with approvalId - already handled
      // via ToolApprovalResponsePart.
      if (output is ToolResultExecutionDeniedOutput) {
        final approvalId = openaiProviderOptions?['approvalId'];
        if (approvalId is String && approvalId.trim().isNotEmpty) {
          return const _SkipFunctionCallOutput();
        }
      }

      return switch (output) {
        ToolResultTextOutput(:final value) => value,
        ToolResultErrorTextOutput(:final value) => value,
        ToolResultExecutionDeniedOutput(:final reason) =>
          (reason != null && reason.trim().isNotEmpty)
              ? reason.trim()
              : 'Tool execution denied.',
        ToolResultJsonOutput(:final value) => jsonEncode(value),
        ToolResultErrorJsonOutput(:final value) => jsonEncode(value),
        ToolResultContentOutput(:final value) => value
            .map((item) {
              switch (item) {
                case ToolResultContentText(:final text):
                  return {'type': 'input_text', 'text': text};

                case ToolResultContentImageData(:final data, :final mediaType):
                  return {
                    'type': 'input_image',
                    'image_url': 'data:$mediaType;base64,$data',
                  };

                case ToolResultContentImageUrl(:final url):
                  return {
                    'type': 'input_image',
                    'image_url': url,
                  };

                case ToolResultContentFileData(
                    :final data,
                    :final mediaType,
                    :final filename,
                  ):
                  return {
                    'type': 'input_file',
                    'filename': (filename != null && filename.isNotEmpty)
                        ? filename
                        : 'data',
                    'file_data': 'data:$mediaType;base64,$data',
                  };

                default:
                  return null;
              }
            })
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
      };
    }

    for (final message in prompt.messages) {
      if (message.role == PromptRole.system) {
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
        if (part
            case ToolApprovalResponsePart(
              :final approvalId,
              :final approved,
            )) {
          if (message.role != PromptRole.tool) {
            throw const InvalidRequestError(
              'ToolApprovalResponsePart must be emitted from a tool message.',
            );
          }
          flush();

          if (approvalId.trim().isEmpty) {
            throw const InvalidRequestError(
              'ToolApprovalResponsePart.approvalId cannot be empty.',
            );
          }

          if (!processedApprovalIds.add(approvalId)) {
            continue;
          }

          // AI SDK parity: when store=true, reference the approval request item.
          if (store) {
            apiMessages.add({'type': 'item_reference', 'id': approvalId});
          }

          apiMessages.add({
            'type': 'mcp_approval_response',
            'approval_request_id': approvalId,
            'approve': approved,
          });
          continue;
        }

        PromptRole effectiveRole;
        if (part case ToolCallPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else if (part case ToolResultPart(:final overrideRole)) {
          effectiveRole = overrideRole ?? message.role;
        } else {
          effectiveRole = message.role;
        }

        if (part
            case ToolCallPart(
              :final toolCallId,
              :final toolName,
              :final input,
              providerOptions: final po,
            )) {
          if (effectiveRole != PromptRole.assistant) {
            throw const InvalidRequestError(
              'ToolCallPart must be emitted from an assistant message.',
            );
          }

          flush();

          final itemId = openAiItemIdFromProviderOptions(
            mergeProviderOptions(message.providerOptions, po),
          );

          apiMessages.add({
            'type': 'function_call',
            'call_id': toolCallId,
            'name': toolName,
            'arguments': jsonEncode(input),
            if (itemId != null) 'id': itemId,
          });
          continue;
        }

        if (part
            case ToolResultPart(
              :final toolCallId,
              :final output,
              providerOptions: final po,
            )) {
          if (effectiveRole != PromptRole.tool) {
            throw const InvalidRequestError(
              'ToolResultPart must be emitted from a tool message.',
            );
          }

          flush();

          final mergedProviderOptions = mergeProviderOptions(
            mergeProviderOptions(message.providerOptions, po),
            output.providerOptions,
          );

          final outputValue = functionCallOutputValueForToolResult(
            output,
            mergedProviderOptions,
          );
          if (outputValue is _SkipFunctionCallOutput) {
            continue;
          }

          apiMessages.add({
            'type': 'function_call_output',
            'call_id': toolCallId,
            'output': outputValue,
          });
          continue;
        }

        if (effectiveRole == PromptRole.assistant && part is TextPart) {
          final text = part.text;
          if (text.trim().isEmpty) continue;

          flush();

          final itemId = openAiItemIdFromProviderOptions(
            mergeProviderOptions(message.providerOptions, part.providerOptions),
          );

          // AI SDK parity: when store=true, reference the stored item.
          if (store && itemId != null) {
            apiMessages.add({'type': 'item_reference', 'id': itemId});
            continue;
          }

          apiMessages.add({
            'role': 'assistant',
            if (message.name != null && message.name!.trim().isNotEmpty)
              'name': message.name,
            'content': [
              {'type': 'output_text', 'text': text}
            ],
            if (itemId != null) 'id': itemId,
          });
          continue;
        }

        final targetRole = switch (effectiveRole) {
          PromptRole.user => 'user',
          PromptRole.assistant => 'assistant',
          PromptRole.system => throw const InvalidRequestError(
              'System messages must be handled separately.'),
          PromptRole.tool => throw const InvalidRequestError(
              "Tool role messages cannot contain non-tool parts."),
        };
        if (currentRole != null && currentRole != targetRole) {
          flush();
        }
        currentRole ??= targetRole;
        currentName ??= message.name;

        currentContentParts.addAll(toContentParts(part, role: targetRole));
      }

      flush();
    }

    return apiMessages;
  }
}

class _SkipFunctionCallOutput {
  const _SkipFunctionCallOutput();
}
