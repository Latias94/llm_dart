import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_result_util.dart';
import 'anthropic_tool_result_projection.dart';

final class AnthropicProjectedResultToolCall {
  final String toolCallId;
  final String toolName;
  final Object? input;
  final bool providerExecuted;
  final bool isDynamic;
  final String? title;
  final ProviderMetadata? providerMetadata;

  const AnthropicProjectedResultToolCall({
    required this.toolCallId,
    required this.toolName,
    required this.input,
    this.providerExecuted = false,
    this.isDynamic = false,
    this.title,
    this.providerMetadata,
  });

  ToolCallContent get content {
    return ToolCallContent(
      toolCallId: toolCallId,
      toolName: toolName,
      input: input,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
    );
  }

  ToolCallContentPart get contentPart {
    return ToolCallContentPart(
      content,
      providerMetadata: providerMetadata,
    );
  }
}

AnthropicProjectedResultToolCall? projectAnthropicResultToolUsePart(
  Map<String, Object?> part,
) {
  final toolCallId = anthropicResultAsString(part['id']);
  final toolName = anthropicResultAsString(part['name']);
  if (toolCallId == null || toolName == null) {
    return null;
  }

  return AnthropicProjectedResultToolCall(
    toolCallId: toolCallId,
    toolName: toolName,
    input: normalizeJsonValue(part['input']),
    providerMetadata: anthropicResultProviderMetadata({
      'caller': part['caller'],
    }),
  );
}

AnthropicProjectedResultToolCall? projectAnthropicResultServerToolUsePart(
  Map<String, Object?> part,
) {
  final toolCallId = anthropicResultAsString(part['id']);
  final toolName = anthropicResultAsString(part['name']);
  if (toolCallId == null || toolName == null) {
    return null;
  }

  return AnthropicProjectedResultToolCall(
    toolCallId: toolCallId,
    toolName: toolName,
    input: normalizeJsonValue(part['input']),
    providerExecuted: true,
    isDynamic: true,
    providerMetadata: anthropicResultProviderMetadata({
      'providerToolName': toolName,
      'caller': part['caller'],
    }),
  );
}

AnthropicProjectedResultToolCall? projectAnthropicResultMcpToolUsePart(
  Map<String, Object?> part,
) {
  final toolCallId = anthropicResultAsString(part['id']);
  final rawToolName = anthropicResultAsString(part['name']);
  if (toolCallId == null || rawToolName == null) {
    return null;
  }

  final serverName = anthropicResultAsString(part['server_name']);
  return AnthropicProjectedResultToolCall(
    toolCallId: toolCallId,
    toolName: 'mcp.$rawToolName',
    input: normalizeJsonValue(part['input']),
    providerExecuted: true,
    isDynamic: true,
    title: serverName,
    providerMetadata: anthropicResultProviderMetadata({
      'serverName': serverName,
    }),
  );
}

Iterable<ContentPart> projectAnthropicResultToolResultParts({
  required String blockType,
  required Map<String, Object?> block,
  required ProviderMetadata? descriptorProviderMetadata,
  required String? descriptorToolName,
  required bool? descriptorIsDynamic,
}) sync* {
  final toolUseId = anthropicResultAsString(block['tool_use_id']);
  if (toolUseId == null) {
    return;
  }

  final toolName =
      descriptorToolName ?? anthropicFallbackToolResultName(blockType);
  final metadata = anthropicResultProviderMetadata({
    ...anthropicResultProviderMetadataValues(descriptorProviderMetadata),
    'partType': blockType,
  });

  yield ToolResultContentPart(
    ToolResultContent(
      toolCallId: toolUseId,
      toolName: toolName,
      toolOutput: anthropicToolResultOutput(blockType, block),
      isDynamic:
          descriptorIsDynamic ?? isAnthropicDynamicToolResultBlock(blockType),
    ),
    providerMetadata: metadata,
  );

  final customKind = anthropicToolResultCustomKind(blockType);
  if (customKind != null) {
    yield CustomContentPart(
      kind: customKind,
      data: anthropicToolResultReplayPayload(
        blockType: blockType,
        block: block,
        toolCallId: toolUseId,
        toolName: toolName,
      ),
      providerMetadata: metadata,
    );
  }

  if (blockType == 'web_search_tool_result') {
    for (final source in projectAnthropicWebSearchToolResultSources(block)) {
      yield SourceContentPart(source);
    }
  }
}
