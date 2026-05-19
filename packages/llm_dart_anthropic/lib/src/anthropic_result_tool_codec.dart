import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_result_tool_projection.dart';
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
  final projected = projectAnthropicResultToolUsePart(part);
  if (projected == null) {
    return null;
  }

  toolDescriptors[projected.toolCallId] = AnthropicResultToolDescriptor(
    toolName: projected.toolName,
    providerMetadata: projected.providerMetadata,
    isDynamic: false,
  );

  return projected.contentPart;
}

ToolCallContentPart? decodeAnthropicResultServerToolUsePart(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) {
  final projected = projectAnthropicResultServerToolUsePart(part);
  if (projected == null) {
    return null;
  }

  toolDescriptors[projected.toolCallId] = AnthropicResultToolDescriptor(
    toolName: projected.toolName,
    providerMetadata: projected.providerMetadata,
    isDynamic: true,
  );

  return projected.contentPart;
}

ToolCallContentPart? decodeAnthropicResultMcpToolUsePart(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) {
  final projected = projectAnthropicResultMcpToolUsePart(part);
  if (projected == null) {
    return null;
  }

  toolDescriptors[projected.toolCallId] = AnthropicResultToolDescriptor(
    toolName: projected.toolName,
    providerMetadata: projected.providerMetadata,
    isDynamic: true,
  );

  return projected.contentPart;
}

Iterable<ContentPart> decodeAnthropicResultToolResultParts(
  Map<String, Object?> part,
  Map<String, AnthropicResultToolDescriptor> toolDescriptors,
) sync* {
  final type = anthropicResultAsString(part['type']);
  if (type == null) {
    return;
  }

  final toolUseId = anthropicResultAsString(part['tool_use_id']);
  final descriptor = toolDescriptors[toolUseId];
  yield* projectAnthropicResultToolResultParts(
    blockType: type,
    block: part,
    descriptorProviderMetadata: descriptor?.providerMetadata,
    descriptorToolName: descriptor?.toolName,
    descriptorIsDynamic: descriptor?.isDynamic,
  );
}
