import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_code_execution_replay.dart';

bool isAnthropicToolResultBlockType(String? blockType) {
  return blockType == 'mcp_tool_result' ||
      blockType == 'web_fetch_tool_result' ||
      blockType == 'web_search_tool_result' ||
      blockType == 'code_execution_tool_result' ||
      blockType == 'bash_code_execution_tool_result' ||
      blockType == 'text_editor_code_execution_tool_result' ||
      blockType == 'tool_search_tool_result';
}

bool isAnthropicDynamicToolResultBlock(String blockType) {
  return isAnthropicToolResultBlockType(blockType);
}

String anthropicFallbackToolResultName(String blockType) {
  switch (blockType) {
    case 'mcp_tool_result':
      return 'mcp.unknown';
    case 'web_fetch_tool_result':
      return 'web_fetch';
    case 'web_search_tool_result':
      return 'web_search';
    case 'code_execution_tool_result':
    case 'bash_code_execution_tool_result':
    case 'text_editor_code_execution_tool_result':
      return 'code_execution';
    case 'tool_search_tool_result':
      return 'tool_search';
    default:
      return 'tool';
  }
}

bool isAnthropicErrorToolResult(
  String blockType,
  Map<String, Object?> block,
) {
  if (blockType == 'mcp_tool_result') {
    return block['is_error'] == true;
  }

  final content = _asObjectMap(block['content']);
  final contentType = _asString(content?['type']);
  return contentType != null && contentType.endsWith('_error');
}

ToolOutput anthropicToolResultOutput(
  String blockType,
  Map<String, Object?> block,
) {
  return ToolOutput.fromValue(
    normalizeJsonValue(block['content']),
    isError: isAnthropicErrorToolResult(blockType, block),
  );
}

String? anthropicToolResultCustomKind(String blockType) {
  switch (blockType) {
    case 'web_fetch_tool_result':
      return 'anthropic.result.web_fetch';
    case 'web_search_tool_result':
      return 'anthropic.result.web_search';
    case 'tool_search_tool_result':
      return 'anthropic.result.tool_search';
    case 'code_execution_tool_result':
    case 'bash_code_execution_tool_result':
    case 'text_editor_code_execution_tool_result':
      return 'anthropic.result.code_execution';
    default:
      return null;
  }
}

Map<String, Object?> anthropicToolResultReplayPayload({
  required String blockType,
  required Map<String, Object?> block,
  required String toolCallId,
  required String toolName,
}) {
  final replayToolName = isAnthropicExecutionToolResultBlock(blockType)
      ? 'code_execution'
      : toolName;

  return {
    if (isAnthropicExecutionToolResultBlock(blockType))
      'schema': AnthropicCodeExecutionReplay.schema,
    'replayRole': 'tool',
    'toolCallId': toolCallId,
    'toolName': replayToolName,
    if (isAnthropicExecutionToolResultBlock(blockType)) 'blockType': blockType,
    'block': normalizeJsonValue(block),
  };
}

bool isAnthropicExecutionToolResultBlock(String blockType) {
  return blockType == 'code_execution_tool_result' ||
      blockType == 'bash_code_execution_tool_result' ||
      blockType == 'text_editor_code_execution_tool_result';
}

Map<String, Object?>? _asObjectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  return null;
}

String? _asString(Object? value) {
  return value is String ? value : null;
}
