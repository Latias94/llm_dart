import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_support.dart';
import 'openai_responses_tool_search_projection.dart';
import 'openai_streaming_support.dart';

GenerateTextResult decodeOpenAIResponsesGenerateResponse(
  Map<String, Object?> response, {
  List<ModelWarning> warnings = const [],
}) {
  _throwIfOpenAIResponsesError(response);

  final content = <ContentPart>[];
  final collectedLogprobs = <Object?>[];
  final hostedToolSearchCallIds = <String>[];
  var hasToolCalls = false;

  for (final item in _openAIResponsesOutputItems(response)) {
    final type = openAIResponsesAsString(item['type']);
    if (type == 'message') {
      collectOpenAIResponsesMessageOutputLogprobs(
        item,
        into: collectedLogprobs,
      );
      content.addAll(decodeOpenAIResponsesMessageOutput(item));
      continue;
    }

    if (type == 'reasoning') {
      content.addAll(decodeOpenAIResponsesReasoningOutput(item));
      continue;
    }

    if (type == 'function_call') {
      hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesFunctionCallOutput(item);
      if (toolCall != null) {
        content.add(toolCall);
      }
      continue;
    }

    if (type == 'mcp_approval_request') {
      hasToolCalls = true;
      content.addAll(decodeOpenAIResponsesMcpApprovalRequestOutput(item));
      continue;
    }

    if (type == 'mcp_call') {
      hasToolCalls = true;
      content.addAll(decodeOpenAIResponsesMcpCallOutput(item));
      continue;
    }

    if (type == 'code_interpreter_call') {
      hasToolCalls = true;
      content.addAll(decodeOpenAIResponsesCodeInterpreterCallOutput(item));
      continue;
    }

    if (type == 'image_generation_call') {
      hasToolCalls = true;
      content.addAll(decodeOpenAIResponsesImageGenerationCallOutput(item));
      continue;
    }

    if (type == 'file_search_call') {
      hasToolCalls = true;
      content.addAll(decodeOpenAIResponsesFileSearchCallOutput(item));
      continue;
    }

    if (type == 'web_search_call') {
      hasToolCalls = true;
      content.addAll(decodeOpenAIResponsesWebSearchCallOutput(item));
      continue;
    }

    if (type == 'tool_search_call') {
      hasToolCalls = true;
      final toolCall = decodeOpenAIResponsesToolSearchCallOutput(item);
      if (toolCall != null) {
        content.add(toolCall);
        if (toolCall.toolCall.providerExecuted) {
          hostedToolSearchCallIds.add(toolCall.toolCall.toolCallId);
        }
      }
      continue;
    }

    if (type == 'tool_search_output') {
      hasToolCalls = true;
      final toolResult = decodeOpenAIResponsesToolSearchOutput(
        item,
        fallbackToolCallId: openAIResponsesAsString(item['call_id']) == null
            ? openAIResponsesTakeHostedToolSearchCallId(
                hostedToolSearchCallIds,
              )
            : null,
      );
      if (toolResult != null) {
        content.add(toolResult);
      }
      continue;
    }

    final customPart = decodeOpenAIResponsesCustomOutput(item);
    if (customPart != null) {
      content.add(customPart);
    }
  }

  final rawFinishReason = openAIResponsesResponseFinishReason(response);

  return GenerateTextResult(
    content: content,
    finishReason: mapOpenAIResponsesFinishReason(
      rawReason: rawFinishReason,
      hasToolCalls: hasToolCalls,
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
      logprobs: collectedLogprobs,
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

FinishReason mapOpenAIResponsesFinishReason({
  required String? rawReason,
  required bool hasToolCalls,
  required String? status,
}) {
  if (status == 'failed') {
    return FinishReason.error;
  }

  if (rawReason == null) {
    return hasToolCalls ? FinishReason.toolCalls : FinishReason.stop;
  }

  if (rawReason == 'max_output_tokens') {
    return FinishReason.maxTokens;
  }

  if (rawReason == 'content_filter') {
    return FinishReason.contentFilter;
  }

  if (rawReason == 'cancelled') {
    return FinishReason.aborted;
  }

  return hasToolCalls ? FinishReason.toolCalls : FinishReason.other;
}

UsageStats? decodeOpenAIResponsesUsage(Map<String, Object?>? usage) {
  if (usage == null) {
    return null;
  }

  final inputTokens = openAIResponsesAsInt(usage['input_tokens']);
  final outputTokens = openAIResponsesAsInt(usage['output_tokens']);
  final totalTokens = openAIResponsesAsInt(usage['total_tokens']) ??
      ((inputTokens != null && outputTokens != null)
          ? inputTokens + outputTokens
          : null);
  final outputDetails = openAIResponsesAsMap(usage['output_tokens_details']);

  return UsageStats(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: totalTokens,
    reasoningTokens: openAIResponsesAsInt(
      outputDetails?['reasoning_tokens'],
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

List<Map<String, Object?>> _openAIResponsesOutputItems(
  Map<String, Object?> response,
) {
  final output = openAIResponsesAsList(response['output']);
  final items = <Map<String, Object?>>[];

  for (final rawItem in output) {
    final item = openAIResponsesAsMap(rawItem);
    if (item != null) {
      items.add(item);
    }
  }

  return items;
}
