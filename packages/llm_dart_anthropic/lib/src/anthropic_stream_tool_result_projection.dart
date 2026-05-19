import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_util.dart';
import 'anthropic_tool_result_projection.dart';

Iterable<LanguageModelStreamEvent> emitAnthropicImmediateToolResultEvents({
  required String blockType,
  required Map<String, Object?> contentBlock,
  required ProviderMetadata? descriptorProviderMetadata,
  required String? descriptorToolName,
  required bool? descriptorIsDynamic,
}) sync* {
  final toolUseId = anthropicStreamAsString(contentBlock['tool_use_id']);
  if (toolUseId == null) {
    yield CustomEvent(
      kind: 'anthropic.$blockType',
      data: contentBlock,
    );
    return;
  }

  final providerMetadata = anthropicStreamProviderMetadata({
    ...anthropicStreamProviderMetadataValues(descriptorProviderMetadata),
    'blockType': blockType,
  });
  final toolName =
      descriptorToolName ?? anthropicFallbackToolResultName(blockType);

  yield ToolResultEvent(
    toolResult: ToolResultContent(
      toolCallId: toolUseId,
      toolName: toolName,
      toolOutput: anthropicToolResultOutput(blockType, contentBlock),
      isDynamic:
          descriptorIsDynamic ?? isAnthropicDynamicToolResultBlock(blockType),
    ),
    providerMetadata: providerMetadata,
  );

  final customKind = anthropicToolResultCustomKind(blockType);
  if (customKind != null) {
    yield CustomEvent(
      kind: customKind,
      data: anthropicToolResultReplayPayload(
        blockType: blockType,
        block: contentBlock,
        toolCallId: toolUseId,
        toolName: toolName,
      ),
      providerMetadata: providerMetadata,
    );
  }

  if (blockType == 'web_search_tool_result') {
    yield* emitAnthropicWebSearchToolResultSourceEvents(contentBlock);
  }
}

Iterable<SourceEvent> emitAnthropicWebSearchToolResultSourceEvents(
  Map<String, Object?> contentBlock,
) sync* {
  for (final source
      in projectAnthropicWebSearchToolResultSources(contentBlock)) {
    yield SourceEvent(source);
  }
}
