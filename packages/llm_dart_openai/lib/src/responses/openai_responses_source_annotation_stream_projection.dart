import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_source_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import '../common/openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesOutputTextAnnotationAddedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  final annotation = openAIResponsesAsMap(chunk['annotation']);
  final sourceEvent = decodeOpenAIResponsesSourceEvent(
    annotation,
    emittedAnnotationKeys: state.emittedAnnotationKeys,
  );
  if (sourceEvent != null) {
    yield sourceEvent;
  }
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesContentPartDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final part = openAIResponsesAsMap(chunk['part']);
  if (part == null || openAIResponsesAsString(part['type']) != 'output_text') {
    return;
  }

  appendOpenAILogprobs(
    state.logprobs,
    openAIResponsesJsonListOrNull(part['logprobs']),
  );

  for (final rawAnnotation in openAIResponsesAsList(part['annotations'])) {
    final annotation = openAIResponsesAsMap(rawAnnotation);
    final sourceEvent = decodeOpenAIResponsesSourceEvent(
      annotation,
      emittedAnnotationKeys: state.emittedAnnotationKeys,
    );
    if (sourceEvent != null) {
      yield sourceEvent;
    }
  }

  final textId = openAIResponsesResolveTextId(chunk, null);
  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: textId,
    metadata: () => metadata.textPart(part),
    allowUnstarted: true,
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }
}
