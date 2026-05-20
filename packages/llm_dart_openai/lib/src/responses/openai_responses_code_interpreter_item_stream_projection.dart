import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import 'openai_responses_code_interpreter_stream_support.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

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

  yield* openAIResponsesEnsureCodeInterpreterInputStarted(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    containerId: projection.containerId,
    metadata: () => projection.providerMetadata,
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
    yield* openAIResponsesFinishCodeInterpreterInput(
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
