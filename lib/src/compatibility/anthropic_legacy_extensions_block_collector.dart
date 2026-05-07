part of 'anthropic_legacy_extensions.dart';

final class _AnthropicLegacyMessageBlockCollector {
  final ChatRole messageRole;
  final int messageIndex;
  final List<Tool> messageTools = <Tool>[];
  final List<AnthropicLegacyPromptBlock> promptBlocks =
      <AnthropicLegacyPromptBlock>[];
  AnthropicLegacyCacheControl? cacheControl;

  _AnthropicLegacyMessageBlockCollector({
    required this.messageRole,
    required this.messageIndex,
  });

  void collect(
    Object? rawBlock, {
    required int blockIndex,
  }) {
    final path =
        'messages[$messageIndex].extensions.anthropic.contentBlocks[$blockIndex]';
    final block = _asMap(rawBlock, path: path);

    if (_isAnthropicCacheMarker(block)) {
      _collectCacheMarker(block, path: path);
      return;
    }

    switch (block['type']) {
      case 'tools':
        _collectToolsBlock(block, path: path);
        return;
      case 'text':
        promptBlocks.add(_parseTextBlock(block, path: path));
        return;
      case 'image':
        _requireRole(
          ChatRole.user,
          'Anthropic compatibility only supports raw image blocks on user messages.',
        );
        promptBlocks.add(_parseImageBlock(block, path: path));
        return;
      case 'document':
        _requireRole(
          ChatRole.user,
          'Anthropic compatibility only supports raw document blocks on user messages.',
        );
        promptBlocks.add(_parseDocumentBlock(block, path: path));
        return;
      case 'tool_use':
      case 'server_tool_use':
        _requireRole(
          ChatRole.assistant,
          'Anthropic compatibility only supports raw tool-use blocks on assistant messages.',
        );
        promptBlocks.add(_parseToolUseBlock(block, path: path));
        return;
      case 'mcp_tool_use':
        _requireRole(
          ChatRole.assistant,
          'Anthropic compatibility only supports raw MCP tool-use blocks on assistant messages.',
        );
        promptBlocks.add(_parseMcpToolUseBlock(block, path: path));
        return;
      case 'tool_result':
        _requireRole(
          ChatRole.user,
          'Anthropic compatibility only supports raw tool-result blocks on user messages.',
        );
        promptBlocks.add(_parseToolResultBlock(block, path: path));
        return;
      case 'mcp_tool_result':
        _requireRole(
          ChatRole.user,
          'Anthropic compatibility only supports raw MCP tool-result blocks on user messages.',
        );
        promptBlocks.add(_parseMcpToolResultBlock(block, path: path));
        return;
      case 'web_search_tool_result':
        _collectProviderNativeToolResultBlock(
          block,
          path: path,
          roleError:
              'Anthropic compatibility only supports raw web-search tool-result blocks on user messages.',
          expectedType: 'web_search_tool_result',
          expectedContentType: List,
          customKind: 'anthropic.result.web_search',
        );
        return;
      case 'web_fetch_tool_result':
        _collectProviderNativeToolResultBlock(
          block,
          path: path,
          roleError:
              'Anthropic compatibility only supports raw web-fetch tool-result blocks on user messages.',
          expectedType: 'web_fetch_tool_result',
          expectedContentType: Map,
          customKind: 'anthropic.result.web_fetch',
        );
        return;
      case 'code_execution_tool_result':
      case 'bash_code_execution_tool_result':
      case 'text_editor_code_execution_tool_result':
        _requireRole(
          ChatRole.user,
          'Anthropic compatibility only supports raw ${block['type']} blocks on user messages.',
        );
        _throwBridgeIncompatibleExecutionResultBlock(
          _parseRequiredString(
            block['type'],
            path: '$path.type',
          ),
        );
      case 'tool_search_tool_result':
        _collectProviderNativeToolResultBlock(
          block,
          path: path,
          roleError:
              'Anthropic compatibility only supports raw tool_search_tool_result blocks on user messages.',
          expectedType: 'tool_search_tool_result',
          expectedContentType: Map,
          customKind: 'anthropic.result.tool_search',
        );
        return;
      default:
        throw UnsupportedError(
          'Anthropic compatibility only supports raw text/image/document/tool replay blocks, cache markers, and tools blocks inside legacy message extensions.',
        );
    }
  }

  void validateMessageContent(String content) {
    if (messageRole == ChatRole.system || content.isNotEmpty) {
      return;
    }

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

  AnthropicLegacyMessageAnalysis build() {
    return AnthropicLegacyMessageAnalysis(
      messageTools: messageTools,
      promptBlocks: promptBlocks,
      cacheControl: cacheControl,
    );
  }

  void _collectCacheMarker(
    Map<String, Object?> block, {
    required String path,
  }) {
    final parsedCacheControl = _parseCacheControl(
      block['cache_control'],
      path: '$path.cache_control',
    );

    if (cacheControl != null && cacheControl != parsedCacheControl) {
      throw UnsupportedError(
        'Anthropic compatibility does not support multiple cache policies in one legacy message.',
      );
    }

    cacheControl = parsedCacheControl;
  }

  void _collectToolsBlock(
    Map<String, Object?> block, {
    required String path,
  }) {
    if (block.containsKey('cache_control')) {
      throw UnsupportedError(
        'Anthropic compatibility expects tool cache metadata to be carried by the cache marker block, not the tools block itself.',
      );
    }

    messageTools.addAll(_parseToolsBlock(block, path: path));
  }

  void _collectProviderNativeToolResultBlock(
    Map<String, Object?> block, {
    required String path,
    required String roleError,
    required String expectedType,
    required Type expectedContentType,
    required String customKind,
  }) {
    _requireRole(ChatRole.user, roleError);
    promptBlocks.add(
      _parseProviderNativeToolResultBlock(
        block,
        path: path,
        expectedType: expectedType,
        expectedContentType: expectedContentType,
        customKind: customKind,
      ),
    );
  }

  void _requireRole(ChatRole expected, String message) {
    if (messageRole != expected) {
      throw UnsupportedError(message);
    }
  }
}
