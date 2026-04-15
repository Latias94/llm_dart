part of 'openai_responses_codec.dart';

extension _OpenAIResponsesCodecResponseDecoder on OpenAIResponsesCodec {
  GenerateTextResult _decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    _throwIfError(response);

    final content = <ContentPart>[];
    final collectedLogprobs = <Object?>[];
    var hasToolCalls = false;

    for (final item in _outputItems(response)) {
      final type = _asString(item['type']);
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

      final customPart = decodeOpenAIResponsesCustomOutput(item);
      if (customPart != null) {
        content.add(customPart);
      }
    }

    final rawFinishReason = _responseFinishReason(response);

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(
        rawReason: rawFinishReason,
        hasToolCalls: hasToolCalls,
        status: _asString(response['status']),
      ),
      rawFinishReason: rawFinishReason,
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: openAIResponsesResponseMetadata(
        response,
        logprobs: collectedLogprobs,
      ),
      warnings: warnings,
    );
  }

  void _throwIfError(Map<String, Object?> response) {
    final error = _asMap(response['error']);
    if (error == null) {
      return;
    }

    final message = _asString(error['message']) ?? 'OpenAI response error';
    final type = _asString(error['type']);
    final code = error['code'];
    throw StateError(
      'OpenAI response error: $message'
      '${type == null ? '' : ' (type: $type)'}'
      '${code == null ? '' : ' (code: $code)'}',
    );
  }

  FinishReason _mapFinishReason({
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

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['input_tokens']);
    final outputTokens = _asInt(usage['output_tokens']);
    final totalTokens = _asInt(usage['total_tokens']) ??
        ((inputTokens != null && outputTokens != null)
            ? inputTokens + outputTokens
            : null);
    final outputDetails = _asMap(usage['output_tokens_details']);

    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      reasoningTokens: _asInt(outputDetails?['reasoning_tokens']),
    );
  }

  List<Map<String, Object?>> _outputItems(Map<String, Object?> response) {
    final output = _asList(response['output']);
    final items = <Map<String, Object?>>[];

    for (final rawItem in output) {
      final item = _asMap(rawItem);
      if (item != null) {
        items.add(item);
      }
    }

    return items;
  }

  String? _responseFinishReason(Map<String, Object?> response) {
    final incompleteDetails = _asMap(response['incomplete_details']);
    return _asString(incompleteDetails?['reason']);
  }
}
