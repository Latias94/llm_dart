import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_file_search_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesFileSearchItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesFileSearchCall(
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

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesFileSearchItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesFileSearchCall(
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
