part of 'anthropic_legacy_extensions.dart';

bool _isAnthropicCacheMarker(Map<String, Object?> block) {
  return block['type'] == 'text' &&
      block['text'] == '' &&
      block['cache_control'] != null;
}

AnthropicLegacyTextBlock _parseTextBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'text' && key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/text/cache_control in raw text blocks.',
    );
  }

  final text = block['text'];
  if (text is! String) {
    throw UnsupportedError(
      'Anthropic text block at $path requires a string text field.',
    );
  }

  return AnthropicLegacyTextBlock(
    text: text,
    cacheControl: block['cache_control'] == null
        ? null
        : _parseCacheControl(
            block['cache_control'],
            path: '$path.cache_control',
          ),
  );
}

AnthropicLegacyImageBlock _parseImageBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'source' && key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/source/cache_control in raw image blocks.',
    );
  }

  final source = _asMap(
    block['source'],
    path: '$path.source',
  );
  final sourceType = source['type'];
  if (sourceType is! String || sourceType.isEmpty) {
    throw UnsupportedError(
      'Anthropic image source at $path.source requires a type.',
    );
  }

  final cacheControl = block['cache_control'] == null
      ? null
      : _parseCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (!_supportedImageMediaTypes.contains(mediaType)) {
        throw UnsupportedError(
          'Anthropic compatibility only supports JPEG, PNG, GIF, and WebP raw image blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyImageBlock(
        mediaType: mediaType,
        bytes: _decodeBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'url':
      return AnthropicLegacyImageBlock(
        mediaType: 'image/*',
        uri: _parseHttpUri(
          source['url'],
          path: '$path.source.url',
        ),
        cacheControl: cacheControl,
      );
    default:
      throw UnsupportedError(
        'Anthropic compatibility only supports base64 and url raw image sources.',
      );
  }
}

AnthropicLegacyDocumentBlock _parseDocumentBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'source' &&
        key != 'title' &&
        key != 'cache_control',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/source/title/cache_control in raw document blocks.',
    );
  }

  final source = _asMap(
    block['source'],
    path: '$path.source',
  );
  final sourceType = source['type'];
  if (sourceType is! String || sourceType.isEmpty) {
    throw UnsupportedError(
      'Anthropic document source at $path.source requires a type.',
    );
  }

  final title = block['title'];
  if (title != null && (title is! String || title.isEmpty)) {
    throw UnsupportedError(
      'Anthropic document title at $path.title must be a non-empty string when provided.',
    );
  }

  final cacheControl = block['cache_control'] == null
      ? null
      : _parseCacheControl(
          block['cache_control'],
          path: '$path.cache_control',
        );

  switch (sourceType) {
    case 'base64':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'application/pdf') {
        throw UnsupportedError(
          'Anthropic compatibility only supports base64 PDF raw document blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: _decodeBase64(
          data,
          path: '$path.source.data',
        ),
        cacheControl: cacheControl,
      );
    case 'text':
      final mediaType = _parseRequiredString(
        source['media_type'],
        path: '$path.source.media_type',
      );
      if (mediaType != 'text/plain') {
        throw UnsupportedError(
          'Anthropic compatibility only supports text/plain raw text-document blocks.',
        );
      }

      final data = _parseRequiredString(
        source['data'],
        path: '$path.source.data',
      );

      return AnthropicLegacyDocumentBlock(
        mediaType: mediaType,
        title: title as String?,
        bytes: utf8.encode(data),
        cacheControl: cacheControl,
      );
    default:
      throw UnsupportedError(
        'Anthropic compatibility only supports base64 PDF and text/plain raw document sources.',
      );
  }
}

AnthropicLegacyToolUseBlock _parseToolUseBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'id' && key != 'name' && key != 'input',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/id/name/input in raw tool-use blocks.',
    );
  }

  final type = _parseRequiredString(
    block['type'],
    path: '$path.type',
  );

  return AnthropicLegacyToolUseBlock(
    toolCallId: _parseRequiredString(
      block['id'],
      path: '$path.id',
    ),
    toolName: _parseRequiredString(
      block['name'],
      path: '$path.name',
    ),
    input: _normalizeJsonPayload(
      block['input'],
      path: '$path.input',
    ),
    providerExecuted: type == 'server_tool_use',
    isDynamic: type == 'server_tool_use',
  );
}

AnthropicLegacyToolUseBlock _parseMcpToolUseBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'id' &&
        key != 'name' &&
        key != 'server_name' &&
        key != 'input',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/id/name/server_name/input in raw MCP tool-use blocks.',
    );
  }

  return AnthropicLegacyToolUseBlock(
    toolCallId: _parseRequiredString(
      block['id'],
      path: '$path.id',
    ),
    toolName: 'mcp.${_parseRequiredString(block['name'], path: '$path.name')}',
    title: _parseRequiredString(
      block['server_name'],
      path: '$path.server_name',
    ),
    input: _normalizeJsonPayload(
      block['input'],
      path: '$path.input',
    ),
    providerExecuted: true,
    isDynamic: true,
  );
}

AnthropicLegacyToolResultBlock _parseToolResultBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'tool_use_id' &&
        key != 'content' &&
        key != 'is_error',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/tool_use_id/content/is_error in raw tool-result blocks.',
    );
  }

  final content = block['content'];
  if (content != null && content is! String) {
    throw UnsupportedError(
      'Anthropic compatibility only supports string tool_result content when replaying raw legacy blocks.',
    );
  }

  final isError = block['is_error'];
  if (isError != null && isError is! bool) {
    throw UnsupportedError(
      'Anthropic tool_result is_error at $path.is_error must be a boolean when provided.',
    );
  }

  return AnthropicLegacyToolResultBlock(
    blockType: 'tool_result',
    toolCallId: _parseRequiredString(
      block['tool_use_id'],
      path: '$path.tool_use_id',
    ),
    output: content,
    isError: isError == true,
  );
}

AnthropicLegacyToolResultBlock _parseMcpToolResultBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final extraKeys = block.keys.where(
    (key) =>
        key != 'type' &&
        key != 'tool_use_id' &&
        key != 'content' &&
        key != 'is_error',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/tool_use_id/content/is_error in raw MCP tool-result blocks.',
    );
  }

  final isError = block['is_error'];
  if (isError != null && isError is! bool) {
    throw UnsupportedError(
      'Anthropic mcp_tool_result is_error at $path.is_error must be a boolean when provided.',
    );
  }

  final output = _normalizeJsonPayload(
    block['content'],
    path: '$path.content',
  );
  if (output == null) {
    throw UnsupportedError(
      'Anthropic compatibility requires non-null content for raw MCP tool-result blocks.',
    );
  }

  return AnthropicLegacyToolResultBlock(
    blockType: 'mcp_tool_result',
    toolCallId: _parseRequiredString(
      block['tool_use_id'],
      path: '$path.tool_use_id',
    ),
    output: output,
    isError: isError == true,
  );
}

AnthropicLegacyToolResultBlock _parseProviderNativeToolResultBlock(
  Map<String, Object?> block, {
  required String path,
  required String expectedType,
  required Type expectedContentType,
  required String customKind,
}) {
  final extraKeys = block.keys.where(
    (key) => key != 'type' && key != 'tool_use_id' && key != 'content',
  );
  if (extraKeys.isNotEmpty) {
    throw UnsupportedError(
      'Anthropic compatibility only supports type/tool_use_id/content in raw $expectedType blocks.',
    );
  }

  final content = _normalizeJsonPayload(
    block['content'],
    path: '$path.content',
  );
  final hasExpectedContentShape = expectedContentType == List
      ? content is List
      : expectedContentType == Map
          ? content is Map<String, Object?>
          : false;
  if (content == null || !hasExpectedContentShape) {
    throw UnsupportedError(
      'Anthropic compatibility only supports $expectedContentType content in raw $expectedType blocks.',
    );
  }

  return AnthropicLegacyToolResultBlock(
    blockType: expectedType,
    toolCallId: _parseRequiredString(
      block['tool_use_id'],
      path: '$path.tool_use_id',
    ),
    output: content,
    isError: false,
    customKind: customKind,
    rawBlock: _asMap(
      _normalizeJsonPayload(
        block,
        path: path,
      ),
      path: path,
    ),
  );
}

List<Tool> _parseToolsBlock(
  Map<String, Object?> block, {
  required String path,
}) {
  final rawTools = block['tools'];
  if (rawTools is! List) {
    throw UnsupportedError(
      'Anthropic tools block at $path must contain a tools list.',
    );
  }

  final tools = <Tool>[];
  for (var index = 0; index < rawTools.length; index++) {
    final rawTool = rawTools[index];
    final toolMap = _asMap(rawTool, path: '$path.tools[$index]');
    final tool = Tool.fromJson(
      toolMap.map(
        (key, value) => MapEntry(key, _toDynamic(value)),
      ),
    );

    if (tool.toolType != 'function') {
      throw UnsupportedError(
        'Anthropic compatibility only supports function tools in legacy message extensions.',
      );
    }

    tools.add(tool);
  }

  return tools;
}
