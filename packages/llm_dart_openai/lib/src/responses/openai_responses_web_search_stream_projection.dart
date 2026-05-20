import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_web_search_projection.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesWebSearchItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesWebSearchCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield* _emitToolCallIfNeeded(projection, state);
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesWebSearchItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesWebSearchCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield* _emitToolCallIfNeeded(projection, state);
  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> _emitToolCallIfNeeded(
  OpenAIResponsesWebSearchProjection projection,
  OpenAIResponsesStreamState state,
) sync* {
  if (!state.emittedWebSearchToolCallIds.add(projection.toolCallId)) {
    return;
  }

  yield ToolInputStartEvent(
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesWebSearchToolName,
    providerExecuted: true,
    providerMetadata: projection.providerMetadata,
  );
  yield ToolInputEndEvent(
    toolCallId: projection.toolCallId,
    providerMetadata: projection.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}
