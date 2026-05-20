import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_finish_support.dart';
import 'openai_responses_metadata.dart';
import 'openai_responses_result_item_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_streaming_support.dart';
import 'openai_responses_usage_support.dart';

GenerateTextResult decodeOpenAIResponsesGenerateResponse(
  Map<String, Object?> response, {
  List<ModelWarning> warnings = const [],
}) {
  _throwIfOpenAIResponsesError(response);
  final projection = projectOpenAIResponsesResultContent(response);

  final rawFinishReason = openAIResponsesResponseFinishReason(response);

  return GenerateTextResult(
    content: projection.content,
    finishReason: mapOpenAIResponsesFinishReason(
      rawReason: rawFinishReason,
      hasToolCalls: projection.hasToolCalls,
      status: openAIResponsesAsString(response['status']),
    ),
    rawFinishReason: rawFinishReason,
    responseMetadata: ModelResponseMetadata(
      id: openAIResponsesAsString(response['id']),
      timestamp: openAIResponsesDecodeTimestamp(response['created_at']),
      modelId: openAIResponsesAsString(response['model']),
    ),
    usage: decodeOpenAIResponsesUsage(
      openAIResponsesAsMap(response['usage']),
    ),
    providerMetadata: openAIResponsesResponseMetadata(
      response,
      logprobs: projection.logprobs,
    ),
    warnings: warnings,
  );
}

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

void _throwIfOpenAIResponsesError(Map<String, Object?> response) {
  final error = openAIResponsesAsMap(response['error']);
  if (error == null) {
    return;
  }

  final message =
      openAIResponsesAsString(error['message']) ?? 'OpenAI response error';
  final type = openAIResponsesAsString(error['type']);
  final code = error['code'];
  throw StateError(
    'OpenAI response error: $message'
    '${type == null ? '' : ' (type: $type)'}'
    '${code == null ? '' : ' (code: $code)'}',
  );
}
