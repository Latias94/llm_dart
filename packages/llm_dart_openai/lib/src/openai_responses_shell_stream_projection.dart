import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_shell_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_support.dart';
import 'openai_stream_tool_projection.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesLocalShellItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesLocalShellCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesShellItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesShellCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesShellOutputItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesShellOutput(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
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
      _operationType(item) != 'delete_file') {
    if (!inputState.hasDiff) {
      final diff = _operationDiff(item);
      if (diff != null) {
        yield ToolInputDeltaEvent(
          toolCallId: projection.toolCallId,
          delta: _escapeJsonStringContent(diff),
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
    hasDiff: _operationType(item) == 'delete_file',
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

  if (_operationType(item) == 'delete_file') {
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

  final inputPrefix = _applyPatchInputPrefix(projection.toolCallId, item);
  if (inputPrefix == null) {
    return;
  }

  yield ToolInputDeltaEvent(
    toolCallId: projection.toolCallId,
    delta: inputPrefix,
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesApplyPatchOperationDiffDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  if (outputIndex == null) {
    return;
  }

  final toolState = state.toolCalls[outputIndex];
  final inputState = state.applyPatchInputs[outputIndex];
  final delta = openAIResponsesAsString(chunk['delta']);
  if (toolState == null || inputState == null || delta == null) {
    return;
  }

  inputState.hasDiff = true;
  yield ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(
      openAIResponsesAsString(chunk['item_id']) ?? 'apply_patch',
    ),
    delta: _escapeJsonStringContent(delta),
    providerMetadata: openAIResponsesProviderMetadata({
      'responseId': state.responseId,
      'itemId': openAIResponsesAsString(chunk['item_id']),
      'itemType': 'apply_patch_call',
      'outputIndex': outputIndex,
      'serviceTier': state.serviceTier,
    }),
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesApplyPatchOperationDiffDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  if (outputIndex == null) {
    return;
  }

  final toolState = state.toolCalls[outputIndex];
  final inputState = state.applyPatchInputs[outputIndex];
  if (toolState == null || inputState == null || toolState.endEmitted) {
    return;
  }

  final providerMetadata = openAIResponsesProviderMetadata({
    'responseId': state.responseId,
    'itemId': openAIResponsesAsString(chunk['item_id']),
    'itemType': 'apply_patch_call',
    'outputIndex': outputIndex,
    'serviceTier': state.serviceTier,
  });
  final toolCallId = toolState.resolveToolCallId(
    openAIResponsesAsString(chunk['item_id']) ?? 'apply_patch',
  );

  if (!inputState.hasDiff) {
    final diff = openAIResponsesAsString(chunk['diff']);
    if (diff != null) {
      yield ToolInputDeltaEvent(
        toolCallId: toolCallId,
        delta: _escapeJsonStringContent(diff),
        providerMetadata: providerMetadata,
      );
      inputState.hasDiff = true;
    }
  }

  yield ToolInputDeltaEvent(
    toolCallId: toolCallId,
    delta: '"}}',
    providerMetadata: providerMetadata,
  );
  final endEvent = maybeCreateOpenAIToolInputEndEvent(
    toolState: toolState,
    fallbackToolCallId: toolCallId,
    metadata: () => providerMetadata,
  );
  if (endEvent != null) {
    yield endEvent;
  }
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesApplyPatchOutputItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesApplyPatchOutput(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

String? _applyPatchInputPrefix(
  String toolCallId,
  Map<String, Object?> item,
) {
  final operation = openAIResponsesAsMap(item['operation']);
  final type = openAIResponsesAsString(operation?['type']);
  final path = openAIResponsesAsString(operation?['path']);
  if (type == null || path == null) {
    return null;
  }

  return '{"callId":${jsonEncode(toolCallId)},'
      '"operation":{"type":${jsonEncode(type)},'
      '"path":${jsonEncode(path)},"diff":"';
}

String? _operationType(Map<String, Object?> item) {
  final operation = openAIResponsesAsMap(item['operation']);
  return openAIResponsesAsString(operation?['type']);
}

String? _operationDiff(Map<String, Object?> item) {
  final operation = openAIResponsesAsMap(item['operation']);
  return openAIResponsesAsString(operation?['diff']);
}

String _escapeJsonStringContent(String value) {
  final encoded = jsonEncode(value);
  return encoded.substring(1, encoded.length - 1);
}
