part of 'request_builder.dart';

ProcessedMessages _processAnthropicMessages(List<ChatMessage> messages) {
  final anthropicMessages = <Map<String, dynamic>>[];
  final systemContentBlocks = <Map<String, dynamic>>[];
  final systemMessages = <String>[];

  for (final message in messages) {
    if (message.role == ChatRole.system) {
      final result = _processAnthropicSystemMessage(message);
      systemContentBlocks.addAll(result.contentBlocks);
      systemMessages.addAll(result.plainMessages);
    } else {
      anthropicMessages.add(_convertAnthropicMessage(message));
    }
  }

  return ProcessedMessages(
    anthropicMessages: anthropicMessages,
    systemContentBlocks: systemContentBlocks,
    systemMessages: systemMessages,
  );
}

SystemMessageResult _processAnthropicSystemMessage(ChatMessage message) {
  final contentBlocks = <Map<String, dynamic>>[];
  final plainMessages = <String>[];
  Map<String, dynamic>? cacheControl;

  final anthropicData = message.getExtension<Map<String, dynamic>>(
    'anthropic',
  );

  if (anthropicData != null) {
    final blocks = anthropicData['contentBlocks'] as List<dynamic>?;
    if (blocks != null) {
      for (final block in blocks) {
        if (block is Map<String, dynamic>) {
          if (block['cache_control'] != null && block['text'] == '') {
            cacheControl = block['cache_control'];
            continue;
          }
          if (block['type'] == 'tools') {
            continue;
          }
          contentBlocks.add(block);
        }
      }
    }

    if (message.content.isNotEmpty && cacheControl != null) {
      contentBlocks.add({
        'type': 'text',
        'text': message.content,
        'cache_control': cacheControl,
      });
    }
  } else {
    plainMessages.add(message.content);
  }

  return SystemMessageResult(
    contentBlocks: contentBlocks,
    plainMessages: plainMessages,
    cacheControl: cacheControl,
  );
}

Map<String, dynamic> _convertAnthropicMessage(ChatMessage message) {
  final content = <Map<String, dynamic>>[];
  final anthropicData = message.getExtension<Map<String, dynamic>>(
    'anthropic',
  );

  Map<String, dynamic>? cacheControl;
  if (anthropicData != null) {
    final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
    if (contentBlocks != null) {
      for (final block in contentBlocks) {
        if (block is Map<String, dynamic>) {
          if (block['cache_control'] != null && block['text'] == '') {
            cacheControl = block['cache_control'];
            continue;
          }
          if (block['type'] == 'tools') {
            continue;
          }
          content.add(block);
        }
      }
    }

    if (message.content.isNotEmpty) {
      final textBlock = <String, dynamic>{
        'type': 'text',
        'text': message.content,
      };
      if (cacheControl != null) {
        textBlock['cache_control'] = cacheControl;
      }
      content.add(textBlock);
    }
  } else {
    switch (message.messageType) {
      case TextMessage():
        content.add({'type': 'text', 'text': message.content});
        break;
      case ImageMessage(mime: final mime, data: final data):
        content.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': mime.mimeType,
            'data': base64Encode(data),
          },
        });
        break;
      case ImageUrlMessage(url: final url):
        content.add({
          'type': 'image',
          'source': {
            'type': 'url',
            'url': url,
          },
        });
        break;
      case ToolUseMessage(toolCalls: final toolCalls):
        for (final toolCall in toolCalls) {
          try {
            final input = jsonDecode(toolCall.function.arguments);
            content.add({
              'type': 'tool_use',
              'id': toolCall.id,
              'name': toolCall.function.name,
              'input': input,
            });
          } catch (e) {
            content.add({
              'type': 'text',
              'text':
                  '[Error: Invalid tool call arguments for ${toolCall.function.name}]',
            });
          }
        }
        break;
      case ToolResultMessage(results: final results):
        for (final result in results) {
          var isError = false;
          final resultContent = result.function.arguments;

          try {
            final parsed = jsonDecode(resultContent);
            if (parsed is Map<String, dynamic>) {
              isError = parsed['error'] != null ||
                  parsed['is_error'] == true ||
                  parsed['success'] == false;
            }
          } catch (e) {
            final lowerContent = resultContent.toLowerCase();
            isError = lowerContent.contains('error') ||
                lowerContent.contains('failed') ||
                lowerContent.contains('exception');
          }

          content.add({
            'type': 'tool_result',
            'tool_use_id': result.id,
            'content': resultContent,
            'is_error': isError,
          });
        }
        break;
      default:
        content.add({
          'type': 'text',
          'text': message.content,
        });
    }
  }

  return {
    'role': message.role.name,
    'content': content,
  };
}
