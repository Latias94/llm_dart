import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_tool_search_projection.dart';
import '../tools/openai_stream_tool_projection.dart';
import '../common/openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesToolSearchCallItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final projection = projectOpenAIResponsesToolSearchCall(
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
    fallbackToolName: openAIResponsesToolSearchToolName,
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesToolSearchToolName,
  );

  if (projection.providerExecuted) {
    final startEvent = maybeCreateOpenAIToolInputStartEvent(
      toolState: toolState,
      fallbackToolCallId: projection.toolCallId,
      fallbackToolName: openAIResponsesToolSearchToolName,
      metadata: () => projection.providerMetadata,
      providerExecuted: true,
    );
    if (startEvent != null) {
      yield startEvent;
    }
  }
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesToolSearchCallItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final projection = projectOpenAIResponsesToolSearchCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: outputIndex,
  );
  if (projection == null) {
    return;
  }

  OpenAIStreamToolCallState? toolState =
      outputIndex == null ? null : state.toolCalls.remove(outputIndex);
  toolState ??= OpenAIStreamToolCallState(
    index: outputIndex ?? -1,
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesToolSearchToolName,
  );
  toolState.update(
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesToolSearchToolName,
  );

  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: projection.toolCallId,
    fallbackToolName: openAIResponsesToolSearchToolName,
    metadata: () => projection.providerMetadata,
    providerExecuted: projection.providerExecuted,
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

  if (projection.providerExecuted) {
    state.hostedToolSearchCallIds.add(projection.toolCallId);
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesToolSearchOutputItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final fallbackToolCallId = openAIResponsesAsString(item['call_id']) == null
      ? openAIResponsesTakeHostedToolSearchCallId(
          state.hostedToolSearchCallIds,
        )
      : null;
  final projection = projectOpenAIResponsesToolSearchOutput(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
    fallbackToolCallId: fallbackToolCallId,
  );
  if (projection == null) {
    return;
  }

  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
