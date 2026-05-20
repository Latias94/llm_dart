import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_tool_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCustomToolOutputItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final toolCallId = openAIResponsesAsString(item['call_id']);
  final projection = projectOpenAIResponsesCustomToolOutput(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
    fallbackToolName:
        toolCallId == null ? null : state.customToolNamesByCallId[toolCallId],
  );
  if (projection == null) {
    return;
  }

  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
