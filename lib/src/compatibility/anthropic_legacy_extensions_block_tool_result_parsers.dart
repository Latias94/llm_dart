part of 'anthropic_legacy_extensions.dart';

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
