import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../common/openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesMessageItemAdded(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final textId = openAIResponsesResolveTextId(chunk, item);
  final providerMetadata = metadata.item(item);
  final textStartEvent = maybeCreateOpenAITextStartEvent(
    state: state.textParts,
    id: textId,
    metadata: () => providerMetadata,
  );
  if (textStartEvent != null) {
    yield textStartEvent;
  }
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesMessageItemDone(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final textId = openAIResponsesResolveTextId(chunk, item);
  final providerMetadata = metadata.item(item);
  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: textId,
    metadata: () => providerMetadata,
    allowUnstarted: true,
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesOutputTextDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final textId = openAIResponsesResolveTextId(chunk, null);
  yield* decodeOpenAITextDeltaEvents(
    state: state.textParts,
    id: textId,
    delta: openAIResponsesAsString(chunk['delta']),
    aggregateLogprobs: state.logprobs,
    deltaLogprobs: openAIResponsesJsonListOrNull(chunk['logprobs']),
    startMetadata: metadata.item,
    deltaMetadata: metadata.item,
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesOutputTextDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final textId = openAIResponsesResolveTextId(chunk, null);
  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: textId,
    metadata: metadata.item,
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesReasoningSummaryPartAddedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final reasoningStartEvent = maybeCreateOpenAIReasoningStartEvent(
    state: state.reasoningParts,
    id: openAIResponsesResolveReasoningId(chunk),
    metadata: metadata.item,
  );
  if (reasoningStartEvent != null) {
    yield reasoningStartEvent;
  }
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesReasoningSummaryTextDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  yield* decodeOpenAIReasoningDeltaEvents(
    state: state.reasoningParts,
    id: openAIResponsesResolveReasoningId(chunk),
    delta: openAIResponsesAsString(chunk['delta']),
    startMetadata: metadata.item,
    deltaMetadata: metadata.item,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesReasoningSummaryPartDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
    state: state.reasoningParts,
    id: openAIResponsesResolveReasoningId(chunk),
    metadata: metadata.item,
  );
  if (reasoningEndEvent != null) {
    yield reasoningEndEvent;
  }
}
