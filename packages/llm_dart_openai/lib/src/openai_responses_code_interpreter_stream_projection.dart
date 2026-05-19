import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_stream_tool_projection.dart';
import 'openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCodeInterpreterItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final projection = projectOpenAIResponsesCodeInterpreterCall(
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
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesCodeInterpreterToolName,
  );

  yield* _ensureCodeInterpreterInputStarted(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    containerId: projection.containerId,
    metadata: () => projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCodeInterpreterCodeDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final fallbackToolCallId =
      openAIResponsesAsString(chunk['item_id']) ?? 'code_interpreter';
  final toolState = resolveOpenAIStreamToolCallState(
    state: state,
    index: outputIndex,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
    toolCallId: openAIResponsesAsString(chunk['item_id']),
    toolName: openAIResponsesCodeInterpreterToolName,
    createEphemeralWhenIndexMissing: true,
  );
  ProviderMetadata? itemMetadata() => metadata.item();

  yield* _ensureCodeInterpreterInputStarted(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    containerId: null,
    metadata: itemMetadata,
  );

  final delta = openAIResponsesAsString(chunk['delta']);
  if (delta == null || delta.isEmpty) {
    return;
  }

  final escaped = openAIResponsesEscapeJsonStringContent(delta);
  toolState.update(argumentsDelta: escaped);
  yield ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    delta: escaped,
    providerMetadata: itemMetadata(),
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCodeInterpreterCodeDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final fallbackToolCallId =
      openAIResponsesAsString(chunk['item_id']) ?? 'code_interpreter';
  final toolState = resolveOpenAIStreamToolCallState(
    state: state,
    index: outputIndex,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
    toolCallId: openAIResponsesAsString(chunk['item_id']),
    toolName: openAIResponsesCodeInterpreterToolName,
    createEphemeralWhenIndexMissing: true,
  );

  yield* _finishCodeInterpreterInput(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    containerId: null,
    codeIfMissing: openAIResponsesAsString(chunk['code']),
    metadata: () => metadata.item(),
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCodeInterpreterItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final projection = projectOpenAIResponsesCodeInterpreterCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: outputIndex,
  );
  if (projection == null) {
    return;
  }

  final toolState = outputIndex == null ? null : state.toolCalls[outputIndex];
  if (toolState == null) {
    yield ToolCallEvent(
      toolCall: projection.toToolCall(),
      providerMetadata: projection.providerMetadata,
    );
  } else {
    yield* _finishCodeInterpreterInput(
      toolState: toolState,
      fallbackToolCallId: projection.toolCallId,
      containerId: projection.containerId,
      codeIfMissing: projection.code,
      metadata: () => projection.providerMetadata,
    );
    state.toolCalls.remove(outputIndex!);
  }

  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> _ensureCodeInterpreterInputStarted({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  required String? containerId,
  required ProviderMetadata? Function() metadata,
}) sync* {
  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
    metadata: metadata,
    providerExecuted: true,
  );
  if (startEvent == null) {
    return;
  }

  final prefix = openAIResponsesCodeInterpreterInputPrefix(containerId);
  toolState.update(argumentsDelta: prefix);
  yield startEvent;
  yield ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    delta: prefix,
    providerMetadata: metadata(),
  );
}

Iterable<LanguageModelStreamEvent> _finishCodeInterpreterInput({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  required String? containerId,
  required String? codeIfMissing,
  required ProviderMetadata? Function() metadata,
}) sync* {
  if (toolState.endEmitted) {
    return;
  }

  yield* _ensureCodeInterpreterInputStarted(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    containerId: containerId,
    metadata: metadata,
  );

  final current = toolState.encodedArguments('');
  if (codeIfMissing != null &&
      openAIResponsesCodeInterpreterInputHasOnlyPrefix(current)) {
    final escaped = openAIResponsesEscapeJsonStringContent(codeIfMissing);
    toolState.update(argumentsDelta: escaped);
    yield ToolInputDeltaEvent(
      toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
      delta: escaped,
      providerMetadata: metadata(),
    );
  }

  toolState.update(argumentsDelta: openAIResponsesCodeInterpreterInputSuffix);
  yield ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    delta: openAIResponsesCodeInterpreterInputSuffix,
    providerMetadata: metadata(),
  );

  final resolvedInput = resolveOpenAIStreamToolInput(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
  );
  if (resolvedInput.decodeError != null) {
    yield createOpenAIToolInputErrorEvent(
      input: resolvedInput,
      metadata: metadata,
      providerExecuted: true,
    );
    return;
  }

  final endEvent = maybeCreateOpenAIToolInputEndEvent(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    metadata: metadata,
  );
  if (endEvent != null) {
    yield endEvent;
  }

  yield ToolCallEvent(
    toolCall: ToolCallContent(
      toolCallId: resolvedInput.toolCallId,
      toolName: openAIResponsesCodeInterpreterToolName,
      input: resolvedInput.decodedInput,
      providerExecuted: true,
    ),
    providerMetadata: metadata(),
  );
}
