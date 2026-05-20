import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_projection.dart';
import 'openai_responses_stream_state.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesPartialImageChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  yield projectOpenAIResponsesPartialImageChunk(
    chunk: chunk,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
  ).toEvent();
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesCustomOutputItemDone(
  String? itemType,
  Map<String, Object?> item,
  ProviderMetadata? providerMetadata,
) sync* {
  final projection = projectOpenAIResponsesCustomOutputItem(
    item,
    itemType: itemType,
    providerMetadata: providerMetadata,
  );
  if (projection == null) {
    return;
  }

  yield projection.toEvent();
}
