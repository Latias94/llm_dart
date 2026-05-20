import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_finish_support.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_usage_support.dart';
import 'openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesCreatedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final response = openAIResponsesAsMap(chunk['response']);
  if (response == null) {
    return;
  }

  captureOpenAIResponseMetadata(
    state: state,
    responseId: openAIResponsesAsString(response['id']),
    responseTimestamp: openAIResponsesDecodeTimestamp(response['created_at']),
    responseModelId: openAIResponsesAsString(response['model']),
    serviceTier: openAIResponsesAsString(response['service_tier']),
  );
  final metadataEvent = maybeCreateOpenAIResponseMetadataEvent(
    state: state,
    metadata: () => metadata.response(response),
  );
  if (metadataEvent != null) {
    yield metadataEvent;
  }
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesErrorChunk(
  Map<String, Object?> chunk,
) sync* {
  yield ErrorEvent(
    ModelError.fromUnknown(
      chunk['error'] ?? chunk,
      kind: ModelErrorKind.provider,
    ),
  );
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesTerminalChunk(
  String chunkType,
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final response = openAIResponsesAsMap(chunk['response']);
  if (response == null) {
    return;
  }

  captureOpenAIResponseMetadata(
    state: state,
    responseId: openAIResponsesAsString(response['id']),
    responseTimestamp: openAIResponsesDecodeTimestamp(response['created_at']),
    responseModelId: openAIResponsesAsString(response['model']),
    serviceTier: openAIResponsesAsString(response['service_tier']),
    rawFinishReason: openAIResponsesResponseFinishReason(response),
    usage: decodeOpenAIResponsesUsage(
      openAIResponsesAsMap(response['usage']),
    ),
  );

  final metadataEvent = maybeCreateOpenAIResponseMetadataEvent(
    state: state,
    metadata: () => metadata.response(response),
  );
  if (metadataEvent != null) {
    yield metadataEvent;
  }

  if (chunkType == 'response.failed') {
    final error = response['error'];
    if (error != null) {
      yield ErrorEvent(
        ModelError.fromUnknown(
          error,
          kind: ModelErrorKind.provider,
        ),
      );
    }
  }

  yield FinishEvent(
    finishReason: mapOpenAIResponsesFinishReason(
      rawReason: state.rawFinishReason,
      hasToolCalls: state.hasToolCalls,
      status: chunkType == 'response.failed'
          ? 'failed'
          : openAIResponsesAsString(response['status']),
    ),
    rawFinishReason: state.rawFinishReason,
    usage: state.usage,
    providerMetadata: metadata.response(
      response,
      logprobs: state.logprobs,
    ),
  );
}
