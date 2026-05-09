import 'anthropic_legacy_extensions_models.dart';
import 'anthropic_legacy_extensions_utils.dart';

AnthropicLegacyToolUseBlock parseAnthropicLegacyToolUseBlock(
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

  final type = parseAnthropicLegacyRequiredString(
    block['type'],
    path: '$path.type',
  );

  return AnthropicLegacyToolUseBlock(
    toolCallId: parseAnthropicLegacyRequiredString(
      block['id'],
      path: '$path.id',
    ),
    toolName: parseAnthropicLegacyRequiredString(
      block['name'],
      path: '$path.name',
    ),
    input: normalizeAnthropicLegacyJsonPayload(
      block['input'],
      path: '$path.input',
    ),
    providerExecuted: type == 'server_tool_use',
    isDynamic: type == 'server_tool_use',
  );
}

AnthropicLegacyToolUseBlock parseAnthropicLegacyMcpToolUseBlock(
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
    toolCallId: parseAnthropicLegacyRequiredString(
      block['id'],
      path: '$path.id',
    ),
    toolName:
        'mcp.${parseAnthropicLegacyRequiredString(block['name'], path: '$path.name')}',
    title: parseAnthropicLegacyRequiredString(
      block['server_name'],
      path: '$path.server_name',
    ),
    input: normalizeAnthropicLegacyJsonPayload(
      block['input'],
      path: '$path.input',
    ),
    providerExecuted: true,
    isDynamic: true,
  );
}
