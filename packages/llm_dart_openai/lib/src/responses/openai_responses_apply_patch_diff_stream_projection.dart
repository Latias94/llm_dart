import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_apply_patch_stream_support.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

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
    delta: openAIResponsesApplyPatchEscapeJsonStringContent(delta),
    providerMetadata: openAIResponsesApplyPatchDiffProviderMetadata(
      chunk: chunk,
      state: state,
      outputIndex: outputIndex,
    ),
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

  final providerMetadata = openAIResponsesApplyPatchDiffProviderMetadata(
    chunk: chunk,
    state: state,
    outputIndex: outputIndex,
  );
  final toolCallId = toolState.resolveToolCallId(
    openAIResponsesAsString(chunk['item_id']) ?? 'apply_patch',
  );

  if (!inputState.hasDiff) {
    final diff = openAIResponsesAsString(chunk['diff']);
    if (diff != null) {
      yield ToolInputDeltaEvent(
        toolCallId: toolCallId,
        delta: openAIResponsesApplyPatchEscapeJsonStringContent(diff),
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
