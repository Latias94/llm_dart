part of 'openai_chat_completions_codec.dart';

Iterable<TextStreamEvent> _decodeOpenAIChatCompletionsStreamChunk(
  OpenAIChatCompletionsCodec codec,
  Map<String, Object?> chunk,
  OpenAIChatCompletionsStreamState state,
) sync* {
  final metadata = _ChatCompletionsStreamMetadataAdapter(
    support: codec._support,
    state: state,
    chunk: chunk,
  );
  captureOpenAIResponseMetadata(
    state: state,
    responseId: codec._asString(chunk['id']),
    responseModelId: codec._asString(chunk['model']),
    responseTimestamp: codec._decodeResponseTimestamp(chunk),
  );
  final metadataEvent = maybeCreateOpenAIResponseMetadataEvent(
    state: state,
    metadata: metadata.response,
  );
  if (metadataEvent != null) {
    yield metadataEvent;
  }

  final choice = codec._firstChoice(chunk);
  if (choice == null) {
    if (codec._asMap(chunk['error']) case final error?) {
      yield ErrorEvent(
        ModelError.fromUnknown(
          error,
          kind: ModelErrorKind.provider,
        ),
      );
    }
    return;
  }

  final delta = codec._asMap(choice['delta']) ?? const <String, Object?>{};
  final textLogprobs = codec._decodeChatLogprobs(choice['logprobs']);
  captureOpenAIResponseMetadata(
    state: state,
    usage: codec._decodeUsage(codec._asMap(chunk['usage'])),
  );

  yield* codec._support.decodeChunkSources(
    chunk,
    responseId: state.responseId,
    emittedSourceIds: state.emittedSourceIds,
  );

  final reasoningDelta = codec._extractReasoningDelta(delta);
  yield* decodeOpenAIReasoningDeltaEvents(
    state: state.reasoningParts,
    id: OpenAIChatCompletionsCodec._reasoningId,
    delta: reasoningDelta,
    startMetadata: metadata.reasoning,
    deltaMetadata: metadata.reasoning,
  );

  final contentDelta = codec._extractContentDelta(delta);
  yield* decodeOpenAITextDeltaEvents(
    state: state.textParts,
    id: OpenAIChatCompletionsCodec._textId,
    delta: contentDelta,
    aggregateLogprobs: state.logprobs,
    deltaLogprobs: textLogprobs,
    startMetadata: () => metadata.text(textLogprobs),
    deltaMetadata: () => metadata.text(textLogprobs),
  );

  for (final rawToolCall in codec._asList(delta['tool_calls'])) {
    final toolCall = codec._asMap(rawToolCall);
    if (toolCall == null) {
      continue;
    }

    final rawIndex = codec._asInt(toolCall['index']);
    final index = rawIndex ?? state.toolCalls.length;
    final function =
        codec._asMap(toolCall['function']) ?? const <String, Object?>{};
    final deltaResult = consumeOpenAIToolCallDelta(
      state: state,
      index: rawIndex,
      fallbackIndex: index,
      fallbackToolCallId: 'tool_$index',
      toolCallId: codec._asString(toolCall['id']),
      toolName: codec._asString(function['name']),
      argumentsDelta: codec._asString(function['arguments']),
    );
    final toolState = deltaResult.toolState;
    if (toolState.toolCallId == null || toolState.toolName == null) {
      continue;
    }

    final startEvent = maybeCreateOpenAIToolInputStartEvent(
      toolState: toolState,
      fallbackToolCallId: 'tool_$index',
      metadata: () => metadata.tool(index),
    );
    if (startEvent != null) {
      yield startEvent;
    }

    final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
      toolState: toolState,
      fallbackToolCallId: 'tool_$index',
      delta: deltaResult.argumentsDelta,
      metadata: () => metadata.tool(index),
    );
    if (deltaEvent != null) {
      yield deltaEvent;
    }
  }

  final rawFinishReason = codec._asString(choice['finish_reason']);
  if (rawFinishReason == null) {
    return;
  }

  captureOpenAIResponseMetadata(
    state: state,
    rawFinishReason: rawFinishReason,
  );

  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: OpenAIChatCompletionsCodec._textId,
    metadata: () => metadata.text(textLogprobs),
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }

  final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
    state: state.reasoningParts,
    id: OpenAIChatCompletionsCodec._reasoningId,
    metadata: metadata.reasoning,
  );
  if (reasoningEndEvent != null) {
    yield reasoningEndEvent;
  }

  yield* codec._finalizeToolCalls(state, metadata);

  yield FinishEvent(
    finishReason: codec._mapFinishReason(rawFinishReason),
    rawFinishReason: rawFinishReason,
    usage: state.usage,
    providerMetadata: metadata.finish(),
  );
}

final class _ChatCompletionsStreamMetadataAdapter {
  final OpenAIChatCompletionsSupport support;
  final OpenAIChatCompletionsStreamState state;
  final Map<String, Object?> chunk;

  const _ChatCompletionsStreamMetadataAdapter({
    required this.support,
    required this.state,
    required this.chunk,
  });

  ProviderMetadata? response() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? reasoning() => support.providerMetadata({
        'responseId': state.responseId,
      });

  ProviderMetadata? text(List<Object?>? logprobs) => support.providerMetadata({
        'responseId': state.responseId,
        'logprobs': logprobs,
      });

  ProviderMetadata? tool(int index) => support.providerMetadata({
        'responseId': state.responseId,
        'toolIndex': index,
      });

  ProviderMetadata? finish() => support.providerMetadata({
        'responseId': state.responseId,
        'systemFingerprint': chunk['system_fingerprint'] is String
            ? chunk['system_fingerprint'] as String
            : null,
        if (state.logprobs.isNotEmpty)
          'logprobs': List<Object?>.unmodifiable(state.logprobs),
      });
}
