part of 'anthropic_legacy_extensions.dart';

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
