import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import 'openai_responses_code_interpreter_stream_support.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

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

  yield* openAIResponsesEnsureCodeInterpreterInputStarted(
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

  yield* openAIResponsesFinishCodeInterpreterInput(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    containerId: null,
    codeIfMissing: openAIResponsesAsString(chunk['code']),
    metadata: () => metadata.item(),
  );
}
