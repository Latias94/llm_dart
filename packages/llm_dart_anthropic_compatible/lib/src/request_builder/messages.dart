part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension _AnthropicRequestBuilderMessages on AnthropicRequestBuilder {
  ProcessedMessages _processMessages(
    List<ChatMessage> messages,
    ToolNameMapping toolNameMapping,
  ) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemContentBlocks = <Map<String, dynamic>>[];
    final systemMessages = <String>[];

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        final result = _processSystemMessage(message);
        systemContentBlocks.addAll(result.contentBlocks);
        systemMessages.addAll(result.plainMessages);
      } else {
        anthropicMessages.add(_convertMessage(message, toolNameMapping));
      }
    }

    return ProcessedMessages(
      anthropicMessages: anthropicMessages,
      systemContentBlocks: systemContentBlocks,
      systemMessages: systemMessages,
    );
  }

  Map<String, dynamic> _convertMessage(
    ChatMessage message,
    ToolNameMapping toolNameMapping,
  ) {
    final content = <Map<String, dynamic>>[];

    // Protocol-internal: preserve legacy `ChatMessage.extensions` content blocks.
    final anthropicData =
        // ignore: deprecated_member_use
        message.getExtension<Map<String, dynamic>>('anthropic');

    final cacheControlFromMessageOptions =
        _cacheControlFromProviderOptions(message.providerOptions);

    Map<String, dynamic>? cacheControlFromBlocks;
    if (anthropicData != null) {
      final contentBlocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (contentBlocks != null) {
        for (final block in contentBlocks) {
          if (block is Map) {
            final blockMap = Map<String, dynamic>.from(block);
            if (blockMap['cache_control'] != null && blockMap['text'] == '') {
              cacheControlFromBlocks = blockMap['cache_control'];
              continue;
            }
            if (blockMap['type'] == 'tools') {
              continue;
            }
            final copied = Map<String, dynamic>.from(blockMap);
            if (copied['type'] == 'text' &&
                copied['cache_control'] == null &&
                (cacheControlFromBlocks ??
                        cacheControlFromMessageOptions ??
                        _defaultCacheControl) !=
                    null) {
              copied['cache_control'] = cacheControlFromBlocks ??
                  cacheControlFromMessageOptions ??
                  _defaultCacheControl;
            }
            content.add(copied);
          }
        }
      }

      if (message.content.isNotEmpty) {
        final textBlock = <String, dynamic>{
          'type': 'text',
          'text': message.content,
        };
        final effectiveCacheControl = cacheControlFromBlocks ??
            cacheControlFromMessageOptions ??
            _defaultCacheControl;
        if (effectiveCacheControl != null) {
          textBlock['cache_control'] = effectiveCacheControl;
        }
        content.add(textBlock);
      }
    } else {
      final effectiveCacheControl =
          cacheControlFromMessageOptions ?? _defaultCacheControl;
      switch (message.messageType) {
        case TextMessage():
          content.add({
            'type': 'text',
            'text': message.content,
            if (effectiveCacheControl != null)
              'cache_control': effectiveCacheControl,
          });
          break;
        case ImageMessage(mime: final mime, data: final data):
          if (message.content.isNotEmpty) {
            content.add({
              'type': 'text',
              'text': message.content,
              if (effectiveCacheControl != null)
                'cache_control': effectiveCacheControl,
            });
          }
          content.add({
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': mime.mimeType,
              'data': base64Encode(data),
            },
          });
          break;
        case ImageUrlMessage():
          throw const InvalidRequestError(
            'ImageUrlMessage is not supported by the Anthropic Messages API. '
            'Download the image and send it as ImageMessage (base64) instead.',
          );
        case FileMessage(mime: final mime, data: final data):
          if (mime.mimeType != 'application/pdf') {
            throw InvalidRequestError(
              'FileMessage (${mime.mimeType}) is not supported by the Anthropic '
              'Messages API. Only application/pdf is supported.',
            );
          }
          if (message.content.isNotEmpty) {
            content.add({
              'type': 'text',
              'text': message.content,
              if (effectiveCacheControl != null)
                'cache_control': effectiveCacheControl,
            });
          }
          content.add({
            'type': 'document',
            'source': {
              'type': 'base64',
              'media_type': 'application/pdf',
              'data': base64Encode(data),
            },
          });
          break;
        case ToolUseMessage(toolCalls: final toolCalls):
          if (message.content.isNotEmpty) {
            content.add({
              'type': 'text',
              'text': message.content,
              if (effectiveCacheControl != null)
                'cache_control': effectiveCacheControl,
            });
          }
          for (final toolCall in toolCalls) {
            try {
              final input = jsonDecode(toolCall.function.arguments);
              final requestName = toolNameMapping
                  .requestNameForFunction(toolCall.function.name);
              final cacheControlForToolCall =
                  _cacheControlFromProviderOptions(toolCall.providerOptions) ??
                      effectiveCacheControl;
              content.add({
                'type': 'tool_use',
                'id': toolCall.id,
                'name': requestName,
                'input': input,
                if (cacheControlForToolCall != null)
                  'cache_control': cacheControlForToolCall,
              });
            } catch (e) {
              throw InvalidRequestError(
                'Invalid JSON tool call arguments for tool '
                '"${toolCall.function.name}": $e',
              );
            }
          }
          break;
        case ToolResultMessage(results: final results):
          if (message.content.isNotEmpty) {
            content.add({
              'type': 'text',
              'text': message.content,
              if (effectiveCacheControl != null)
                'cache_control': effectiveCacheControl,
            });
          }
          for (final result in results) {
            final resultContent = result.function.arguments;
            final isError = _toolResultIsError(resultContent, result);

            content.add({
              'type': 'tool_result',
              'tool_use_id': result.id,
              'content': resultContent,
              'is_error': isError,
              if ((_cacheControlFromProviderOptions(result.providerOptions) ??
                      effectiveCacheControl) !=
                  null)
                'cache_control':
                    _cacheControlFromProviderOptions(result.providerOptions) ??
                        effectiveCacheControl,
            });
          }
          break;
      }
    }

    return {
      'role': message.role.name,
      'content': content,
    };
  }

  bool _toolResultIsError(String content, ToolCall toolResult) {
    final explicit = readProviderOption<bool>(
      toolResult.providerOptions,
      config.providerId,
      'isError',
      fallbackProviderId: _providerOptionsFallbackId,
    );
    if (explicit != null) return explicit;

    final explicitSnake = readProviderOption<bool>(
      toolResult.providerOptions,
      config.providerId,
      'is_error',
      fallbackProviderId: _providerOptionsFallbackId,
    );
    if (explicitSnake != null) return explicitSnake;

    try {
      final parsed = jsonDecode(content);
      if (parsed is Map) {
        final map = Map<String, dynamic>.from(parsed);
        return map['error'] != null ||
            map['is_error'] == true ||
            map['success'] == false;
      }
    } catch (_) {
      // fall through
    }

    final lower = content.toLowerCase();
    return lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('exception');
  }
}
