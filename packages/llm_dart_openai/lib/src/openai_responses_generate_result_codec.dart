import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_finish_support.dart';
import 'openai_responses_metadata.dart';
import 'openai_responses_result_item_projection.dart';
import 'openai_responses_stream_util.dart';
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
