import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_result_util.dart';
import 'anthropic_tool_result_projection.dart';

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
  return isAnthropicToolResultBlockType(type);
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
  final toolName =
      descriptor?.toolName ?? anthropicFallbackToolResultName(type);
  final metadata = anthropicResultProviderMetadata({
    ...anthropicResultProviderMetadataValues(descriptor?.providerMetadata),
    'partType': type,
  });

  yield ToolResultContentPart(
    ToolResultContent(
      toolCallId: toolUseId,
      toolName: toolName,
      toolOutput: anthropicToolResultOutput(type, part),
      isDynamic: descriptor?.isDynamic ?? true,
    ),
    providerMetadata: metadata,
  );

  final customKind = anthropicToolResultCustomKind(type);
  if (customKind != null) {
    yield CustomContentPart(
      kind: customKind,
      data: anthropicToolResultReplayPayload(
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
