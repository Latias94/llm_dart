part of 'package:llm_dart_anthropic_compatible/request_builder.dart';

extension _AnthropicRequestBuilderSystemMessages on AnthropicRequestBuilder {
  SystemMessageResult _processSystemMessage(ChatMessage message) {
    final contentBlocks = <Map<String, dynamic>>[];
    final plainMessages = <String>[];
    final cacheControlFromMessageOptions =
        _cacheControlFromProviderOptions(message.providerOptions);
    Map<String, dynamic>? cacheControlFromBlocks;

    // Protocol-internal: preserve legacy `ChatMessage.extensions` content blocks.
    final anthropicData =
        // ignore: deprecated_member_use
        message.getExtension<Map<String, dynamic>>('anthropic');

    if (anthropicData != null) {
      final blocks = anthropicData['contentBlocks'] as List<dynamic>?;
      if (blocks != null) {
        for (final block in blocks) {
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
            final effectiveCacheControl = cacheControlFromBlocks ??
                cacheControlFromMessageOptions ??
                _defaultCacheControl;
            if (copied['type'] == 'text' &&
                copied['cache_control'] == null &&
                effectiveCacheControl != null) {
              copied['cache_control'] = effectiveCacheControl;
            }
            contentBlocks.add(copied);
          }
        }
      }

      final effectiveCacheControl = cacheControlFromBlocks ??
          cacheControlFromMessageOptions ??
          _defaultCacheControl;
      if (message.content.isNotEmpty && effectiveCacheControl != null) {
        contentBlocks.add({
          'type': 'text',
          'text': message.content,
          'cache_control': effectiveCacheControl,
        });
      } else if (message.content.isNotEmpty && effectiveCacheControl == null) {
        plainMessages.add(message.content);
      }
    } else {
      final effectiveCacheControl = cacheControlFromMessageOptions;
      if (effectiveCacheControl != null) {
        contentBlocks.add({
          'type': 'text',
          'text': message.content,
          'cache_control': effectiveCacheControl,
        });
      } else {
        plainMessages.add(message.content);
      }
    }

    return SystemMessageResult(
      contentBlocks: contentBlocks,
      plainMessages: plainMessages,
    );
  }

  void _addSystemContent(Map<String, dynamic> body, ProcessedMessages data) {
    final allSystemContent = <Map<String, dynamic>>[];

    if (config.systemPrompt != null && config.systemPrompt!.isNotEmpty) {
      allSystemContent.add({
        'type': 'text',
        'text': config.systemPrompt!,
      });
    }

    allSystemContent.addAll(
      data.systemContentBlocks.map((b) => Map<String, dynamic>.from(b)),
    );

    for (final message in data.systemMessages) {
      allSystemContent.add({
        'type': 'text',
        'text': message,
      });
    }

    final cacheControl = _defaultCacheControl;
    if (cacheControl != null) {
      for (final block in allSystemContent) {
        if (block['type'] == 'text' && block['cache_control'] == null) {
          block['cache_control'] = cacheControl;
        }
      }
    }

    if (allSystemContent.isNotEmpty) {
      body['system'] = allSystemContent;
    }
  }
}
