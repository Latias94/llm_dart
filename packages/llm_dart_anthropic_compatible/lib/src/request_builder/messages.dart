part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension _AnthropicRequestBuilderMessages on AnthropicRequestBuilder {
  Object _decodeToolResultContentIfJsonArray(String raw) {
    final trimmed = raw.trim();
    if (!trimmed.startsWith('[')) return raw;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! List) return raw;

      final blocks = decoded
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false);

      // Only treat JSON arrays that look like Anthropic content blocks as rich content.
      final looksLikeContentBlocks = blocks.isEmpty ||
          blocks.every((b) =>
              b['type'] is String && (b['type'] as String).trim().isNotEmpty);

      return looksLikeContentBlocks ? blocks : raw;
    } catch (_) {
      return raw;
    }
  }

  ProcessedMessages _processMessages(
    List<ChatMessage> messages,
    ToolNameMapping toolNameMapping,
  ) {
    final anthropicMessages = <Map<String, dynamic>>[];
    final systemContentBlocks = <Map<String, dynamic>>[];
    final systemMessages = <String>[];
    var didSeeNonSystemMessage = false;

    for (final message in messages) {
      if (message.role == ChatRole.system) {
        if (didSeeNonSystemMessage) {
          throw const InvalidRequestError(
            'Multiple system messages that are separated by user/assistant '
            'messages are not supported. Put all system content at the '
            'beginning of the prompt.',
          );
        }
        final result = _processSystemMessage(message);
        systemContentBlocks.addAll(result.contentBlocks);
        systemMessages.addAll(result.plainMessages);
      } else {
        didSeeNonSystemMessage = true;
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

    final anthropicData = message.getProtocolPayload<Map<String, dynamic>>(
      'anthropic',
    );

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
            if (effectiveCacheControl != null)
              'cache_control': effectiveCacheControl,
          });
          break;
        case ImageUrlMessage(url: final url):
          if (message.content.isNotEmpty) {
            content.add({
              'type': 'text',
              'text': message.content,
              if (effectiveCacheControl != null)
                'cache_control': effectiveCacheControl,
            });
          }

          final trimmed = url.trim();
          final isHttp =
              trimmed.startsWith('http://') || trimmed.startsWith('https://');
          if (!isHttp) {
            throw InvalidRequestError(
              'ImageUrlMessage must be an http(s) URL. Got: "$url"',
            );
          }

          content.add({
            'type': 'image',
            'source': {
              'type': 'url',
              'url': trimmed,
            },
            if (effectiveCacheControl != null)
              'cache_control': effectiveCacheControl,
          });
          break;
        case FileMessage(mime: final mime, data: final data):
          if (mime.mimeType != 'application/pdf' &&
              mime.mimeType != 'text/plain') {
            throw InvalidRequestError(
              'FileMessage (${mime.mimeType}) is not supported by the Anthropic '
              'Messages API. Only application/pdf and text/plain are supported.',
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

          final docOptions =
              _documentOptionsFromProviderOptions(message.providerOptions);
          final source = mime.mimeType == 'text/plain'
              ? <String, dynamic>{
                  'type': 'text',
                  'media_type': 'text/plain',
                  'data': utf8.decode(data, allowMalformed: true),
                }
              : <String, dynamic>{
                  'type': 'base64',
                  'media_type': 'application/pdf',
                  'data': base64Encode(data),
                };
          content.add({
            'type': 'document',
            'source': source,
            if (docOptions.title != null) 'title': docOptions.title,
            if (docOptions.context != null) 'context': docOptions.context,
            if (docOptions.citationsEnabled) 'citations': {'enabled': true},
            if (effectiveCacheControl != null)
              'cache_control': effectiveCacheControl,
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
            final isError =
                _toolResultIsError(resultContent, result.providerOptions);

            content.add({
              'type': 'tool_result',
              'tool_use_id': result.id,
              'content': _decodeToolResultContentIfJsonArray(resultContent),
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

    String wireRoleForMessage(ChatMessage message) {
      // Anthropic Messages API does not support a dedicated `tool` role.
      // Tool results are represented as `tool_result` blocks inside `user` messages.
      if (message.messageType is ToolResultMessage) return 'user';

      return switch (message.role) {
        ChatRole.system => 'system',
        ChatRole.user => 'user',
        ChatRole.assistant => 'assistant',
        ChatRole.tool => 'user',
      };
    }

    return {
      'role': wireRoleForMessage(message),
      'content': content,
    };
  }

  bool _toolResultIsError(String content, ProviderOptions providerOptions) {
    final explicit = readProviderOption<bool>(
      providerOptions,
      config.providerId,
      'isError',
      fallbackProviderId: _providerOptionsFallbackId,
    );
    if (explicit != null) return explicit;

    final explicitSnake = readProviderOption<bool>(
      providerOptions,
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
