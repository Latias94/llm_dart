import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesPartialImageChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  yield CustomEvent(
    kind: 'openai.image_generation_call.partial_image',
    data: {
      'item_id': openAIResponsesAsString(chunk['item_id']),
      'output_index': openAIResponsesAsInt(chunk['output_index']),
      'partial_image_b64': openAIResponsesAsString(
        chunk['partial_image_b64'],
      ),
    },
    providerMetadata: metadata.custom({
      'responseId': state.responseId,
      'itemId': openAIResponsesAsString(chunk['item_id']),
      'itemType': 'image_generation_call.partial_image',
      'outputIndex': openAIResponsesAsInt(chunk['output_index']),
      'serviceTier': state.serviceTier,
    }),
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesCustomOutputItemDone(
  String? itemType,
  Map<String, Object?> item,
  ProviderMetadata? providerMetadata,
) sync* {
  if (itemType == null || itemType == 'reasoning') {
    return;
  }

  yield CustomEvent(
    kind: 'openai.$itemType',
    data: item,
    providerMetadata: providerMetadata,
  );
}
