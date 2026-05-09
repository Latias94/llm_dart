import 'dart:convert';

import '../../../../models/chat_models.dart';
import '../../../../models/tool_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';

/// Provider-local codec for Google chat message and tool payloads.
final class GoogleChatMessageCodec {
  final GoogleClient client;
  final GoogleConfig config;

  GoogleChatMessageCodec({
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
        parts.add(_convertImage(mime, data));
        break;
      case FileMessage(mime: final mime, data: final data):
        parts.add(
          _convertFile(
            mime,
            data,
            maxInlineDataSize: config.maxInlineDataSize,
          ),
        );
        break;
      case ImageUrlMessage(url: final url):
        parts.add(_convertImageUrl(url));
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        parts.addAll(_convertToolUse(toolCalls));
        break;
      case ToolResultMessage(results: final results):
        parts.addAll(_convertToolResult(results));
        break;
    }

    return {
      'role': role,
      'parts': parts,
    };
  }

  Map<String, dynamic> convertTool(Tool tool) {
    try {
      final schema = tool.function.parameters.toJson();

      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'No description provided',
        'parameters': schema,
      };
    } catch (e) {
      client.logger.warning('Failed to convert tool ${tool.function.name}: $e');
      return {
        'name': tool.function.name,
        'description': tool.function.description.isNotEmpty
            ? tool.function.description
            : 'Tool with invalid schema',
        'parameters': {
          'type': 'object',
          'properties': {},
        },
      };
    }
  }

  Map<String, dynamic> convertToolChoice(
    ToolChoice toolChoice,
    List<Tool> tools,
  ) {
    switch (toolChoice) {
      case AutoToolChoice():
        return {
          'function_calling_config': {
            'mode': 'AUTO',
          },
        };
      case AnyToolChoice():
        return {
          'function_calling_config': {
            'mode': 'ANY',
          },
        };
      case SpecificToolChoice(toolName: final toolName):
        final toolExists = tools.any((tool) => tool.function.name == toolName);
        if (!toolExists) {
          client.logger.warning(
            'Tool "$toolName" specified in SpecificToolChoice not found in '
            'available tools',
          );
          return {
            'function_calling_config': {
              'mode': 'AUTO',
            },
          };
        }
        return {
          'function_calling_config': {
            'mode': 'ANY',
            'allowed_function_names': [toolName],
          },
        };
      case NoneToolChoice():
        return {
          'function_calling_config': {
            'mode': 'NONE',
          },
        };
    }
  }

  Map<String, dynamic> _convertImage(ImageMime mime, List<int> data) {
    final supportedFormats = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    ];
    if (!supportedFormats.contains(mime.mimeType)) {
      return {
        'text':
            '[Unsupported image format: ${mime.mimeType}. Supported formats: ${supportedFormats.join(', ')}]',
      };
    }

    return {
      'inlineData': {
        'mimeType': mime.mimeType,
        'data': base64Encode(data),
      },
    };
  }

  Map<String, dynamic> _convertFile(
    FileMime mime,
    List<int> data, {
    required int maxInlineDataSize,
  }) {
    if (data.length > maxInlineDataSize) {
      return {
        'text':
            '[File too large: ${data.length} bytes. Maximum size: $maxInlineDataSize bytes]',
      };
    } else if (mime.isDocument || mime.isAudio || mime.isVideo) {
      return {
        'inlineData': {
          'mimeType': mime.mimeType,
          'data': base64Encode(data),
        },
      };
    }

    return {
      'text':
          '[File type ${mime.description} (${mime.mimeType}) may not be supported by Google AI]',
    };
  }

  Map<String, dynamic> _convertImageUrl(String url) {
    return {
      'text':
          '[Image URL not supported by Google. Please upload the image directly: $url]',
    };
  }

  List<Map<String, dynamic>> _convertToolUse(List<ToolCall> toolCalls) {
    final parts = <Map<String, dynamic>>[];

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
          'text': '[Error: Invalid tool call arguments for '
              '${toolCall.function.name}]',
        });
      }
    }

    return parts;
  }

  List<Map<String, dynamic>> _convertToolResult(List<ToolCall> results) {
    final parts = <Map<String, dynamic>>[];

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

    return parts;
  }
}
