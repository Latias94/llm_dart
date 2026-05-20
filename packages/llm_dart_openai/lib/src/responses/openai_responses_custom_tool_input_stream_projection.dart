import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_tool_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesCustomToolCallInputDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final fallbackToolCallId =
      openAIResponsesAsString(chunk['item_id']) ?? 'custom_tool';
  final deltaResult = consumeOpenAIToolCallDelta(
    state: state,
    index: outputIndex,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCustomToolFallbackToolName,
    argumentsDelta: openAIResponsesAsString(chunk['delta']),
    createEphemeralWhenIndexMissing: true,
  );

  final toolState = deltaResult.toolState;
  final resolvedToolCallId = toolState.resolveToolCallId(fallbackToolCallId);
  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    fallbackToolName: openAIResponsesCustomToolFallbackToolName,
    metadata: () => metadata.item(),
  );
  if (startEvent != null) {
    yield startEvent;
  }

  final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    delta: deltaResult.argumentsDelta,
    metadata: () => metadata.item(),
  );
  if (deltaEvent != null) {
    yield deltaEvent;
  }
}
