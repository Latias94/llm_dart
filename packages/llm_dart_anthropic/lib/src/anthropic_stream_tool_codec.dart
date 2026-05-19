import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'anthropic_stream_state.dart';
import 'anthropic_stream_tool_projection.dart';
import 'anthropic_stream_util.dart';
import 'anthropic_tool_result_projection.dart';

final class AnthropicStreamToolCodec {
  const AnthropicStreamToolCodec();

  Iterable<LanguageModelStreamEvent> emitPrepopulatedToolCall(
    Map<String, Object?> part,
    AnthropicMessagesStreamState state,
  ) sync* {
    final toolCallId = anthropicStreamAsString(part['id']);
    final toolName = anthropicStreamAsString(part['name']);
    if (toolCallId == null || toolName == null) {
      return;
    }

    final providerMetadata = anthropicStreamProviderMetadata({
      'caller': part['caller'],
    });
    final projectedToolCall = projectAnthropicToolCall(
      toolCallId: toolCallId,
      toolName: toolName,
      input: part['input'],
      providerMetadata: providerMetadata,
    );

    state.toolDescriptorsById[toolCallId] = AnthropicStreamToolDescriptor(
      toolName: toolName,
      providerMetadata: providerMetadata,
      providerExecuted: false,
      isDynamic: false,
      title: null,
    );

    yield* emitAnthropicProjectedToolCallEvents(projectedToolCall);
  }

  Iterable<LanguageModelStreamEvent> startToolBlock({
    required int index,
    required String toolCallId,
    required String toolName,
    required Object? initialInput,
    required bool providerExecuted,
    required bool isDynamic,
    required String? title,
    required Map<String, Object?> metadataValues,
    required AnthropicMessagesStreamState state,
  }) sync* {
    final providerMetadata = anthropicStreamProviderMetadata(metadataValues);
    final projectedToolCall = projectAnthropicToolCall(
      toolCallId: toolCallId,
      toolName: toolName,
      input: initialInput,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
      providerMetadata: providerMetadata,
      emitInputDeltaForNull: false,
    );

    final toolState = AnthropicStreamToolBlockState(
      toolCallId: toolCallId,
      toolName: toolName,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
      providerMetadata: providerMetadata,
    );

    if (projectedToolCall.encodedInput.isNotEmpty) {
      toolState.inputBuffer.write(projectedToolCall.encodedInput);
    }

    state.contentBlocksByIndex[index] = toolState;
    state.toolDescriptorsById[toolCallId] = AnthropicStreamToolDescriptor(
      toolName: toolName,
      providerMetadata: providerMetadata,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
    );

    yield* emitAnthropicToolInputStartEvents(projectedToolCall);
  }

  Iterable<LanguageModelStreamEvent> finishToolBlock(
    AnthropicStreamToolBlockState contentBlock,
    AnthropicMessagesStreamState state,
  ) sync* {
    final encodedInput = contentBlock.inputBuffer.isEmpty
        ? '{}'
        : contentBlock.inputBuffer.toString();
    final projection = projectAnthropicFinishedToolInput(
      toolCallId: contentBlock.toolCallId,
      toolName: contentBlock.toolName,
      encodedInput: encodedInput,
      providerExecuted: contentBlock.providerExecuted,
      isDynamic: contentBlock.isDynamic,
      title: contentBlock.title,
      providerMetadata: contentBlock.providerMetadata,
    );
    yield* projection.emitEvents();

    if (projection.hasToolCall) {
      state.toolDescriptorsById[contentBlock.toolCallId] =
          AnthropicStreamToolDescriptor(
        toolName: contentBlock.toolName,
        providerMetadata: contentBlock.providerMetadata,
        providerExecuted: contentBlock.providerExecuted,
        isDynamic: contentBlock.isDynamic,
        title: contentBlock.title,
      );
    }
  }

  Iterable<LanguageModelStreamEvent> decodeToolInputDelta(
    AnthropicStreamContentBlockState? contentBlock,
    Map<String, Object?> delta,
  ) sync* {
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
  }

  Iterable<LanguageModelStreamEvent> emitImmediateToolResult({
    required String blockType,
    required Map<String, Object?> contentBlock,
    required AnthropicMessagesStreamState state,
  }) sync* {
    final toolUseId = anthropicStreamAsString(contentBlock['tool_use_id']);
    if (toolUseId == null) {
      yield CustomEvent(
        kind: 'anthropic.$blockType',
        data: contentBlock,
      );
      return;
    }

    final descriptor = state.toolDescriptorsById[toolUseId];
    yield* emitAnthropicImmediateToolResultEvents(
      blockType: blockType,
      contentBlock: contentBlock,
      descriptorProviderMetadata: descriptor?.providerMetadata,
      descriptorToolName: descriptor?.toolName,
      descriptorIsDynamic: descriptor?.isDynamic,
    );
  }

  bool isImmediateToolResultBlock(String? blockType) {
    return isAnthropicToolResultBlockType(blockType);
  }
}
