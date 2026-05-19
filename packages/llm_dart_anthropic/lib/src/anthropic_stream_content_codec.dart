import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_content_projection.dart';
import 'anthropic_stream_state.dart';
import 'anthropic_stream_tool_codec.dart';
import 'anthropic_stream_util.dart';

final class AnthropicStreamContentCodec {
  final AnthropicStreamToolCodec toolCodec;

  const AnthropicStreamContentCodec({
    this.toolCodec = const AnthropicStreamToolCodec(),
  });

  Iterable<LanguageModelStreamEvent> decodeContentBlockStart(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = anthropicStreamAsInt(chunk['index']);
    final contentBlock = anthropicStreamAsMap(chunk['content_block']);
    if (index == null || contentBlock == null) {
      return;
    }

    final blockType = anthropicStreamAsString(contentBlock['type']);
    final contentProjection = projectAnthropicStreamContentBlockStart(
      index: index,
      blockType: blockType,
      contentBlock: contentBlock,
    );
    if (contentProjection != null) {
      switch (contentProjection.kind) {
        case AnthropicProjectedStreamContentBlockKind.text:
          state.contentBlocksByIndex[index] = AnthropicStreamTextBlockState(
            id: contentProjection.id,
            providerMetadata: contentProjection.providerMetadata,
          );
        case AnthropicProjectedStreamContentBlockKind.reasoning:
          state.contentBlocksByIndex[index] =
              AnthropicStreamReasoningBlockState(
            id: contentProjection.id,
            providerMetadata: contentProjection.providerMetadata,
          );
      }
      yield contentProjection.event;
      return;
    }

    if (blockType == 'tool_use') {
      yield* toolCodec.startToolBlock(
        index: index,
        toolCallId:
            anthropicStreamAsString(contentBlock['id']) ?? 'tool-$index',
        toolName: anthropicStreamAsString(contentBlock['name']) ?? 'tool',
        initialInput: contentBlock['input'],
        providerExecuted: false,
        isDynamic: false,
        title: null,
        metadataValues: {
          'blockIndex': index,
          'blockType': blockType,
          'caller': contentBlock['caller'],
        },
        state: state,
      );
      return;
    }

    if (blockType == 'server_tool_use') {
      final toolName = anthropicStreamAsString(contentBlock['name']) ?? 'tool';
      yield* toolCodec.startToolBlock(
        index: index,
        toolCallId:
            anthropicStreamAsString(contentBlock['id']) ?? 'tool-$index',
        toolName: toolName,
        initialInput: contentBlock['input'],
        providerExecuted: true,
        isDynamic: true,
        title: null,
        metadataValues: {
          'blockIndex': index,
          'blockType': blockType,
          'providerToolName': toolName,
          'caller': contentBlock['caller'],
        },
        state: state,
      );
      return;
    }

    if (blockType == 'mcp_tool_use') {
      final rawToolName =
          anthropicStreamAsString(contentBlock['name']) ?? 'tool';
      yield* toolCodec.startToolBlock(
        index: index,
        toolCallId:
            anthropicStreamAsString(contentBlock['id']) ?? 'tool-$index',
        toolName: 'mcp.$rawToolName',
        initialInput: contentBlock['input'],
        providerExecuted: true,
        isDynamic: true,
        title: anthropicStreamAsString(contentBlock['server_name']),
        metadataValues: {
          'blockIndex': index,
          'blockType': blockType,
          'serverName': anthropicStreamAsString(contentBlock['server_name']),
        },
        state: state,
      );
      return;
    }

    if (toolCodec.isImmediateToolResultBlock(blockType)) {
      yield* toolCodec.emitImmediateToolResult(
        blockType: blockType!,
        contentBlock: contentBlock,
        state: state,
      );
      return;
    }

    yield projectAnthropicStreamCustomContentBlockEvent(
      blockType: blockType,
      contentBlock: contentBlock,
      providerMetadata: anthropicStreamContentBlockMetadata(
        index: index,
        blockType: blockType,
      ),
    );
  }

  Iterable<LanguageModelStreamEvent> decodeContentBlockDelta(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = anthropicStreamAsInt(chunk['index']);
    final delta = anthropicStreamAsMap(chunk['delta']);
    if (index == null || delta == null) {
      return;
    }

    final deltaType = anthropicStreamAsString(delta['type']);
    final contentBlock = state.contentBlocksByIndex[index];

    if (deltaType == 'input_json_delta') {
      if (contentBlock is! AnthropicStreamToolBlockState) {
        return;
      }

      final partialJson = anthropicStreamAsString(delta['partial_json']);
      if (partialJson == null || partialJson.isEmpty) {
        return;
      }

      contentBlock.inputBuffer.write(partialJson);
      yield ToolInputDeltaEvent(
        toolCallId: contentBlock.toolCallId,
        delta: partialJson,
        providerMetadata: contentBlock.providerMetadata,
      );
      return;
    }

    final event = projectAnthropicStreamContentBlockDelta(
      index: index,
      delta: delta,
      contentBlock: contentBlock,
    );
    if (event != null) {
      yield event;
    }
  }

  Iterable<LanguageModelStreamEvent> decodeContentBlockStop(
    Map<String, Object?> chunk,
    AnthropicMessagesStreamState state,
  ) sync* {
    final index = anthropicStreamAsInt(chunk['index']);
    if (index == null) {
      return;
    }

    final contentBlock = state.contentBlocksByIndex.remove(index);
    if (contentBlock == null) {
      return;
    }

    final event = projectAnthropicStreamContentBlockStop(contentBlock);
    if (event != null) {
      yield event;
      return;
    }

    if (contentBlock is AnthropicStreamToolBlockState) {
      yield* toolCodec.finishToolBlock(contentBlock, state);
    }
  }
}
