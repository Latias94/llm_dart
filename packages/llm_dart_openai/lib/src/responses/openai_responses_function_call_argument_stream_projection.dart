import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesFunctionCallArgumentsDelta(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final fallbackToolCallId =
      openAIResponsesAsString(chunk['item_id']) ?? 'tool';
  final deltaResult = consumeOpenAIToolCallDelta(
    state: state,
    index: outputIndex,
    fallbackToolCallId: fallbackToolCallId,
    argumentsDelta: openAIResponsesAsString(chunk['delta']),
    createEphemeralWhenIndexMissing: true,
  );
  final toolState = deltaResult.toolState;
  final resolvedToolCallId = toolState.resolveToolCallId(fallbackToolCallId);
  ProviderMetadata? itemMetadata() => metadata.item();

  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    metadata: itemMetadata,
  );
  if (startEvent != null) {
    yield startEvent;
  }

  final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    delta: deltaResult.argumentsDelta,
    metadata: itemMetadata,
  );
  if (deltaEvent != null) {
    yield deltaEvent;
  }
}
