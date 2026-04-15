part of 'openai_chat_completions_codec.dart';

extension _OpenAIChatCompletionsCodecResponseDecoder
    on OpenAIChatCompletionsCodec {
  GenerateTextResult _decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) {
    _throwIfError(response);

    final choice = _firstChoice(response);
    final message = _asMap(choice?['message']) ?? const <String, Object?>{};
    final content = <ContentPart>[];
    final textLogprobs = _decodeChatLogprobs(choice?['logprobs']);
    final rawFinishReason = _asString(choice?['finish_reason']);

    final decodedText = _support.decodeAssistantText(message);
    if (decodedText.reasoning case final reasoning? when reasoning.isNotEmpty) {
      content.add(
        ReasoningContentPart(
          reasoning,
          providerMetadata: _support.providerMetadata({
            'finishReason': rawFinishReason,
          }),
        ),
      );
    }

    if (decodedText.text.isNotEmpty) {
      content.add(
        TextContentPart(
          decodedText.text,
          providerMetadata: _support.providerMetadata({
            'finishReason': rawFinishReason,
            'logprobs': textLogprobs,
          }),
        ),
      );
    }

    final toolCalls = _support.decodeToolCalls(
      _asList(message['tool_calls']),
    );
    content.addAll(toolCalls);
    content.addAll(_support.decodeTopLevelSources(response));

    return GenerateTextResult(
      content: content,
      finishReason: _mapFinishReason(rawFinishReason),
      rawFinishReason: rawFinishReason,
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      usage: _decodeUsage(_asMap(response['usage'])),
      providerMetadata: _support.responseMetadata(
        response,
        choice,
        logprobs: textLogprobs,
      ),
      warnings: warnings,
    );
  }

  List<Object?>? _decodeChatLogprobs(Object? value) {
    final logprobs = _asMap(value);
    return _jsonListOrNull(logprobs?['content']);
  }

  UsageStats? _decodeUsage(Map<String, Object?>? usage) {
    if (usage == null) {
      return null;
    }

    final inputTokens = _asInt(usage['prompt_tokens']);
    final outputTokens = _asInt(usage['completion_tokens']);
    final totalTokens = _asInt(usage['total_tokens']) ??
        ((inputTokens != null && outputTokens != null)
            ? inputTokens + outputTokens
            : null);
    final completionDetails = _asMap(usage['completion_tokens_details']);

    return UsageStats(
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      reasoningTokens: _asInt(completionDetails?['reasoning_tokens']),
    );
  }

  FinishReason _mapFinishReason(String? rawReason) {
    return switch (rawReason) {
      null || 'stop' => FinishReason.stop,
      'length' => FinishReason.maxTokens,
      'tool_calls' => FinishReason.toolCalls,
      'content_filter' => FinishReason.contentFilter,
      'cancelled' => FinishReason.aborted,
      _ => FinishReason.other,
    };
  }

  Map<String, Object?>? _firstChoice(Map<String, Object?> response) {
    final choices = _asList(response['choices']);
    if (choices.isEmpty) {
      return null;
    }

    return _asMap(choices.first);
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
      'OpenAI chat-completions error: $message'
      '${type == null ? '' : ' (type: $type)'}'
      '${code == null ? '' : ' (code: $code)'}',
    );
  }
}
