import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_apply_patch_stream_support.dart';
import 'openai_responses_shell_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesApplyPatchItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final projection = projectOpenAIResponsesApplyPatchCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: outputIndex,
  );
  if (projection == null) {
    return;
  }

  final toolState = resolveOpenAIStreamToolCallState(
    state: state,
    index: outputIndex,
    fallbackToolCallId: projection.toolCallId,
    fallbackToolName: openAIResponsesApplyPatchToolName,
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesApplyPatchToolName,
    createEphemeralWhenIndexMissing: true,
  );
  final inputState = OpenAIResponsesApplyPatchStreamState(
    hasDiff: openAIResponsesApplyPatchOperationType(item) == 'delete_file',
  );
  if (outputIndex != null) {
    state.applyPatchInputs[outputIndex] = inputState;
  }

  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    fallbackToolName: openAIResponsesApplyPatchToolName,
    metadata: () => projection.providerMetadata,
  );
  if (startEvent != null) {
    yield startEvent;
  }

  if (openAIResponsesApplyPatchOperationType(item) == 'delete_file') {
    final inputDelta = jsonEncode(projection.input);
    yield ToolInputDeltaEvent(
      toolCallId: projection.toolCallId,
      delta: inputDelta,
      providerMetadata: projection.providerMetadata,
    );
    final endEvent = maybeCreateOpenAIToolInputEndEvent(
      toolState: toolState,
      fallbackToolCallId: projection.toolCallId,
      metadata: () => projection.providerMetadata,
    );
    if (endEvent != null) {
      yield endEvent;
    }
    return;
  }

  final inputPrefix = openAIResponsesApplyPatchInputPrefix(
    projection.toolCallId,
    item,
  );
  if (inputPrefix == null) {
    return;
  }

  yield ToolInputDeltaEvent(
    toolCallId: projection.toolCallId,
    delta: inputPrefix,
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesApplyPatchItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final inputState =
      outputIndex == null ? null : state.applyPatchInputs.remove(outputIndex);
  final toolState =
      outputIndex == null ? null : state.toolCalls.remove(outputIndex);
  final projection = projectOpenAIResponsesApplyPatchCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: outputIndex,
  );
  if (projection == null) {
    return;
  }

  if (toolState != null &&
      inputState != null &&
      !toolState.endEmitted &&
      openAIResponsesApplyPatchOperationType(item) != 'delete_file') {
    if (!inputState.hasDiff) {
      final diff = openAIResponsesApplyPatchOperationDiff(item);
      if (diff != null) {
        yield ToolInputDeltaEvent(
          toolCallId: projection.toolCallId,
          delta: openAIResponsesApplyPatchEscapeJsonStringContent(diff),
          providerMetadata: projection.providerMetadata,
        );
        inputState.hasDiff = true;
      }
    }

    yield ToolInputDeltaEvent(
      toolCallId: projection.toolCallId,
      delta: '"}}',
      providerMetadata: projection.providerMetadata,
    );
    final endEvent = maybeCreateOpenAIToolInputEndEvent(
      toolState: toolState,
      fallbackToolCallId: projection.toolCallId,
      metadata: () => projection.providerMetadata,
    );
    if (endEvent != null) {
      yield endEvent;
    }
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}
