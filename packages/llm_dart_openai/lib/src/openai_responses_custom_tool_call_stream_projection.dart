import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_tool_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_stream_tool_projection.dart';
import 'openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCustomToolCallItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final projection = projectOpenAIResponsesCustomToolCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: outputIndex,
  );
  if (projection == null) {
    return;
  }

  state.customToolNamesByCallId[projection.toolCallId] = projection.toolName;
  final toolState = resolveOpenAIStreamToolCallState(
    state: state,
    index: outputIndex,
    fallbackToolCallId: projection.toolCallId,
    fallbackToolName: projection.toolName,
    toolCallId: projection.toolCallId,
    toolName: projection.toolName,
    createEphemeralWhenIndexMissing: true,
  );

  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    fallbackToolName: projection.toolName,
    metadata: () => projection.providerMetadata,
  );
  if (startEvent != null) {
    yield startEvent;
  }
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCustomToolCallItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  OpenAIStreamToolCallState? toolState =
      outputIndex == null ? null : state.toolCalls.remove(outputIndex);
  final fallbackToolCallId = openAIResponsesAsString(item['call_id']) ??
      openAIResponsesAsString(chunk['item_id']) ??
      'custom_tool';
  final fallbackToolName = openAIResponsesAsString(item['name']) ??
      toolState?.toolName ??
      openAIResponsesCustomToolFallbackToolName;

  toolState ??= OpenAIStreamToolCallState(
    index: outputIndex ?? -1,
    toolCallId: fallbackToolCallId,
    toolName: fallbackToolName,
  );
  toolState.update(
    toolCallId: openAIResponsesAsString(item['call_id']),
    toolName: openAIResponsesAsString(item['name']),
  );

  final projection = projectOpenAIResponsesCustomToolCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: outputIndex,
    fallbackToolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    fallbackToolName: toolState.resolveToolName(fallbackToolName),
    fallbackInput: toolState.arguments.toString(),
  );
  if (projection == null) {
    return;
  }

  state.customToolNamesByCallId[projection.toolCallId] = projection.toolName;
  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    fallbackToolName: projection.toolName,
    metadata: () => projection.providerMetadata,
  );
  if (startEvent != null) {
    yield startEvent;
  }

  final endEvent = maybeCreateOpenAIToolInputEndEvent(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    metadata: () => projection.providerMetadata,
  );
  if (endEvent != null) {
    yield endEvent;
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}
