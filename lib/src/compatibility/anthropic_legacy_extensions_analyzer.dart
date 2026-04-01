part of 'anthropic_legacy_extensions.dart';

AnthropicLegacyExtensionAnalysis analyzeAnthropicLegacyMessageExtensions(
  List<ChatMessage> messages,
) {
  return AnthropicLegacyExtensionAnalysis(
    messageAnalyses: [
      for (var index = 0; index < messages.length; index++)
        analyzeAnthropicLegacyMessage(
          messages[index],
          messageIndex: index,
        ),
    ],
  );
}

AnthropicLegacyMessageAnalysis analyzeAnthropicLegacyMessage(
  ChatMessage message, {
  required int messageIndex,
}) {
  if (message.extensions.isEmpty) {
    return const AnthropicLegacyMessageAnalysis();
  }

  if (message.extensions.length != 1 ||
      !message.extensions.containsKey('anthropic')) {
    throw UnsupportedError(
      'Anthropic compatibility only supports the "anthropic" message extension.',
    );
  }

  if (message.messageType is! TextMessage) {
    throw UnsupportedError(
      'Anthropic compatibility only supports legacy message extensions on text messages.',
    );
  }

  final anthropicData = _asMap(
    message.extensions['anthropic'],
    path: 'messages[$messageIndex].extensions.anthropic',
  );
  final extraKeys = anthropicData.keys.where((key) => key != 'contentBlocks');
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports anthropic.contentBlocks in message extensions.',
    );
  }

  final contentBlocks = anthropicData['contentBlocks'];
  if (contentBlocks == null) {
    if (message.role != ChatRole.system && message.content.isEmpty) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to keep non-empty text content.',
      );
    }

    return const AnthropicLegacyMessageAnalysis();
  }

  if (contentBlocks is! List) {
    throw UnsupportedError(
      'Anthropic contentBlocks must be a list.',
    );
  }

  final messageTools = <Tool>[];
  final promptBlocks = <AnthropicLegacyPromptBlock>[];
  AnthropicLegacyCacheControl? cacheControl;

  for (var blockIndex = 0; blockIndex < contentBlocks.length; blockIndex++) {
    final block = _asMap(
      contentBlocks[blockIndex],
      path:
          'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
    );

    if (_isAnthropicCacheMarker(block)) {
      final parsedCacheControl = _parseCacheControl(
        block['cache_control'],
        path:
            'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex].cache_control',
      );

      if (cacheControl != null && cacheControl != parsedCacheControl) {
        throw UnsupportedError(
          'Anthropic compatibility does not support multiple cache policies in one legacy message.',
        );
      }

      cacheControl = parsedCacheControl;
      continue;
    }

    if (block['type'] == 'tools') {
      if (block.containsKey('cache_control')) {
        throw UnsupportedError(
          'Anthropic compatibility expects tool cache metadata to be carried by the cache marker block, not the tools block itself.',
        );
      }

      messageTools.addAll(
        _parseToolsBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'text') {
      promptBlocks.add(
        _parseTextBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'image') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw image blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseImageBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'document') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw document blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseDocumentBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'tool_use' || block['type'] == 'server_tool_use') {
      if (message.role != ChatRole.assistant) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw tool-use blocks on assistant messages.',
        );
      }

      promptBlocks.add(
        _parseToolUseBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'mcp_tool_use') {
      if (message.role != ChatRole.assistant) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw MCP tool-use blocks on assistant messages.',
        );
      }

      promptBlocks.add(
        _parseMcpToolUseBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'mcp_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw MCP tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseMcpToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
        ),
      );
      continue;
    }

    if (block['type'] == 'web_search_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw web-search tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseProviderNativeToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
          expectedType: 'web_search_tool_result',
          expectedContentType: List,
          customKind: 'anthropic.result.web_search',
        ),
      );
      continue;
    }

    if (block['type'] == 'web_fetch_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw web-fetch tool-result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseProviderNativeToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
          expectedType: 'web_fetch_tool_result',
          expectedContentType: Map,
          customKind: 'anthropic.result.web_fetch',
        ),
      );
      continue;
    }

    if (block['type'] == 'code_execution_tool_result' ||
        block['type'] == 'bash_code_execution_tool_result' ||
        block['type'] == 'text_editor_code_execution_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw ${block['type']} blocks on user messages.',
        );
      }

      _throwBridgeIncompatibleExecutionResultBlock(
        _parseRequiredString(
          block['type'],
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex].type',
        ),
      );
    }

    if (block['type'] == 'tool_search_tool_result') {
      if (message.role != ChatRole.user) {
        throw UnsupportedError(
          'Anthropic compatibility only supports raw tool_search_tool_result blocks on user messages.',
        );
      }

      promptBlocks.add(
        _parseProviderNativeToolResultBlock(
          block,
          path:
              'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]',
          expectedType: 'tool_search_tool_result',
          expectedContentType: Map,
          customKind: 'anthropic.result.tool_search',
        ),
      );
      continue;
    }

    throw UnsupportedError(
      'Anthropic compatibility only supports raw text/image/document/tool replay blocks, cache markers, and tools blocks inside legacy message extensions.',
    );
  }

  if (message.role != ChatRole.system && message.content.isEmpty) {
    if (promptBlocks.isEmpty &&
        (cacheControl != null || messageTools.isNotEmpty)) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to keep non-empty text content.',
      );
    }

    if (promptBlocks.isEmpty) {
      throw UnsupportedError(
        'Anthropic compatibility requires non-system legacy messages with extensions to produce non-empty prompt content.',
      );
    }
  }

  return AnthropicLegacyMessageAnalysis(
    messageTools: messageTools,
    promptBlocks: promptBlocks,
    cacheControl: cacheControl,
  );
}

Never _throwBridgeIncompatibleExecutionResultBlock(String blockType) {
  throw UnsupportedError(
    'Anthropic compatibility does not bridge raw $blockType blocks in legacy message extensions yet. '
    'Use the provider-owned anthropic.result.code_execution replay path in the new Anthropic API, or keep this request on the old Anthropic provider path.',
  );
}
