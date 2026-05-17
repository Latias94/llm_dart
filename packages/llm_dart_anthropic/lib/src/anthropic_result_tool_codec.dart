import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_code_execution_replay.dart';
import 'anthropic_result_util.dart';

final class AnthropicResultToolDescriptor {
  final String toolName;
  final ProviderMetadata? providerMetadata;
  final bool isDynamic;

  const AnthropicResultToolDescriptor({
    required this.toolName,
    required this.providerMetadata,
    required this.isDynamic,
  });
}

bool isAnthropicResultToolResultPart(String? type) {
  return type == 'mcp_tool_result' ||
      type == 'web_fetch_tool_result' ||
      type == 'web_search_tool_result' ||
      type == 'code_execution_tool_result' ||
      type == 'bash_code_execution_tool_result' ||
      type == 'text_editor_code_execution_tool_result' ||
      type == 'tool_search_tool_result';
}

ToolCallContentPart? decodeAnthropicResultToolUsePart(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) {
  final toolCallId = anthropicResultAsString(part['id']);
  final toolName = anthropicResultAsString(part['name']);
  if (toolCallId == null || toolName == null) {
    return null;
  }

  final metadata = anthropicResultProviderMetadata({
    'caller': part['caller'],
  });
  toolDescriptors[toolCallId] = AnthropicResultToolDescriptor(
    toolName: toolName,
    providerMetadata: metadata,
    isDynamic: false,
  );

  return ToolCallContentPart(
    ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: normalizeJsonValue(part['input']),
    ),
    providerMetadata: metadata,
  );
}

ToolCallContentPart? decodeAnthropicResultServerToolUsePart(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) {
  final toolCallId = anthropicResultAsString(part['id']);
  final toolName = anthropicResultAsString(part['name']);
  if (toolCallId == null || toolName == null) {
    return null;
  }

  final metadata = anthropicResultProviderMetadata({
    'providerToolName': toolName,
    'caller': part['caller'],
  });
  toolDescriptors[toolCallId] = AnthropicResultToolDescriptor(
    toolName: toolName,
    providerMetadata: metadata,
    isDynamic: true,
  );

  return ToolCallContentPart(
    ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: normalizeJsonValue(part['input']),
      providerExecuted: true,
      isDynamic: true,
    ),
    providerMetadata: metadata,
  );
}

ToolCallContentPart? decodeAnthropicResultMcpToolUsePart(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) {
  final toolCallId = anthropicResultAsString(part['id']);
  final rawToolName = anthropicResultAsString(part['name']);
  if (toolCallId == null || rawToolName == null) {
    return null;
  }

  final toolName = 'mcp.$rawToolName';
  final serverName = anthropicResultAsString(part['server_name']);
  final metadata = anthropicResultProviderMetadata({
    'serverName': serverName,
  });
  toolDescriptors[toolCallId] = AnthropicResultToolDescriptor(
    toolName: toolName,
    providerMetadata: metadata,
    isDynamic: true,
  );

  return ToolCallContentPart(
    ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: normalizeJsonValue(part['input']),
      providerExecuted: true,
      isDynamic: true,
      title: serverName,
    ),
    providerMetadata: metadata,
  );
}

Iterable<ContentPart> decodeAnthropicResultToolResultParts(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) sync* {
  final type = anthropicResultAsString(part['type']);
  final toolUseId = anthropicResultAsString(part['tool_use_id']);
  if (type == null || toolUseId == null) {
    return;
  }

  final descriptor = toolDescriptors[toolUseId];
  final toolName = descriptor?.toolName ?? _fallbackToolName(type);
  final metadata = anthropicResultProviderMetadata({
    ...anthropicResultProviderMetadataValues(descriptor?.providerMetadata),
    'partType': type,
  });

  yield ToolResultContentPart(
    ToolResultContent(
      toolCallId: toolUseId,
      toolName: toolName,
      toolOutput: _toolResultOutput(type, part),
      isDynamic: descriptor?.isDynamic ?? true,
    ),
    providerMetadata: metadata,
  );

  final customKind = _toolResultCustomKind(type);
  if (customKind != null) {
    yield CustomContentPart(
      kind: customKind,
      data: _toolResultReplayPayload(
        blockType: type,
        block: part,
        toolCallId: toolUseId,
        toolName: toolName,
      ),
      providerMetadata: metadata,
    );
  }

  if (type == 'web_search_tool_result') {
    final resultList = part['content'];
    if (resultList is List) {
      for (final item in resultList) {
        final result = anthropicResultAsMap(item);
        final url = anthropicResultAsString(result?['url']);
        if (url == null) {
          continue;
        }

        yield SourceContentPart(
          SourceReference(
            kind: SourceReferenceKind.url,
            sourceId: url,
            uri: Uri.tryParse(url),
            title: anthropicResultAsString(result?['title']),
            providerMetadata: anthropicResultProviderMetadata({
              'pageAge': anthropicResultAsString(result?['page_age']),
              'resultType': anthropicResultAsString(result?['type']),
            }),
          ),
        );
      }
    }
  }
}

bool _isExecutionToolResultBlock(String blockType) {
  return blockType == 'code_execution_tool_result' ||
      blockType == 'bash_code_execution_tool_result' ||
      blockType == 'text_editor_code_execution_tool_result';
}

bool _isErrorToolResult(String partType, Map<String, Object?> part) {
  if (partType == 'mcp_tool_result') {
    return part['is_error'] == true;
  }

  final content = anthropicResultAsMap(part['content']);
  final contentType = anthropicResultAsString(content?['type']);
  return contentType != null && contentType.endsWith('_error');
}

ToolOutput _toolResultOutput(String partType, Map<String, Object?> part) {
  return ToolOutput.fromValue(
    normalizeJsonValue(part['content']),
    isError: _isErrorToolResult(partType, part),
  );
}

String _fallbackToolName(String partType) {
  switch (partType) {
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

String? _toolResultCustomKind(String partType) {
  switch (partType) {
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

Map<String, Object?> _toolResultReplayPayload({
  required String blockType,
  required Map<String, Object?> block,
  required String toolCallId,
  required String toolName,
}) {
  final replayToolName =
      _isExecutionToolResultBlock(blockType) ? 'code_execution' : toolName;

  return {
    if (_isExecutionToolResultBlock(blockType))
      'schema': AnthropicCodeExecutionReplay.schema,
    'replayRole': 'tool',
    'toolCallId': toolCallId,
    'toolName': replayToolName,
    if (_isExecutionToolResultBlock(blockType)) 'blockType': blockType,
    'block': normalizeJsonValue(block),
  };
}
