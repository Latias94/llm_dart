part of 'openai_responses_codec.dart';

extension _OpenAIResponsesCodecStreamDecoder on OpenAIResponsesCodec {
  Iterable<TextStreamEvent> _handleResponseCreatedChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final response = _asMap(chunk['response']);
    if (response == null) {
      return;
    }

    captureOpenAIResponseMetadata(
      state: state,
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      serviceTier: _asString(response['service_tier']),
    );
    final metadataEvent = maybeCreateOpenAIResponseMetadataEvent(
      state: state,
      metadata: () => metadata.response(response),
    );
    if (metadataEvent != null) {
      yield metadataEvent;
    }
  }

  Iterable<TextStreamEvent> _handleOutputItemAddedChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final item = _asMap(chunk['item']);
    if (item == null) {
      return;
    }

    final itemType = _asString(item['type']);
    final providerMetadata = metadata.item(item);

    if (itemType == 'message') {
      final textId = _resolveTextId(chunk, item);
      final textStartEvent = maybeCreateOpenAITextStartEvent(
        state: state.textParts,
        id: textId,
        metadata: () => providerMetadata,
      );
      if (textStartEvent != null) {
        yield textStartEvent;
      }
      return;
    }

    if (itemType == 'function_call') {
      final outputIndex = _asInt(chunk['output_index']);
      final fallbackToolCallId =
          _asString(item['call_id']) ?? _asString(chunk['item_id']) ?? 'tool';
      final toolState = resolveOpenAIStreamToolCallState(
        state: state,
        index: outputIndex,
        fallbackToolCallId: fallbackToolCallId,
        toolCallId: _asString(item['call_id']),
        toolName: _asString(item['name']),
        title: _asString(item['title']),
        createEphemeralWhenIndexMissing: true,
      );
      final resolvedToolCallId =
          toolState.resolveToolCallId(fallbackToolCallId);
      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: toolState,
        fallbackToolCallId: resolvedToolCallId,
        title: _asString(item['title']),
        metadata: () => providerMetadata,
      );
      if (startEvent != null) {
        yield startEvent;
      }
    }
  }

  Iterable<TextStreamEvent> _handleOutputTextDeltaChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final textId = _resolveTextId(chunk, null);
    yield* decodeOpenAITextDeltaEvents(
      state: state.textParts,
      id: textId,
      delta: _asString(chunk['delta']),
      aggregateLogprobs: state.logprobs,
      deltaLogprobs: _jsonListOrNull(chunk['logprobs']),
      startMetadata: metadata.item,
      deltaMetadata: metadata.item,
    );
  }

  Iterable<TextStreamEvent> _handleOutputTextDoneChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final textId = _resolveTextId(chunk, null);
    final textEndEvent = maybeCreateOpenAITextEndEvent(
      state: state.textParts,
      id: textId,
      metadata: metadata.item,
    );
    if (textEndEvent != null) {
      yield textEndEvent;
    }
  }

  Iterable<TextStreamEvent> _handleReasoningSummaryPartAddedChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final reasoningStartEvent = maybeCreateOpenAIReasoningStartEvent(
      state: state.reasoningParts,
      id: _resolveReasoningId(chunk),
      metadata: metadata.item,
    );
    if (reasoningStartEvent != null) {
      yield reasoningStartEvent;
    }
  }

  Iterable<TextStreamEvent> _handleReasoningSummaryTextDeltaChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    yield* decodeOpenAIReasoningDeltaEvents(
      state: state.reasoningParts,
      id: _resolveReasoningId(chunk),
      delta: _asString(chunk['delta']),
      startMetadata: metadata.item,
      deltaMetadata: metadata.item,
    );
  }

  Iterable<TextStreamEvent> _handleReasoningSummaryPartDoneChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
      state: state.reasoningParts,
      id: _resolveReasoningId(chunk),
      metadata: metadata.item,
    );
    if (reasoningEndEvent != null) {
      yield reasoningEndEvent;
    }
  }

  Iterable<TextStreamEvent> _handleFunctionCallArgumentsDeltaChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final outputIndex = _asInt(chunk['output_index']);
    final fallbackToolCallId = _asString(chunk['item_id']) ?? 'tool';
    final deltaResult = consumeOpenAIToolCallDelta(
      state: state,
      index: outputIndex,
      fallbackToolCallId: fallbackToolCallId,
      argumentsDelta: _asString(chunk['delta']),
      createEphemeralWhenIndexMissing: true,
    );
    final toolState = deltaResult.toolState;
    final resolvedToolCallId = toolState.resolveToolCallId(fallbackToolCallId);
    ProviderMetadata? itemMetadata() => metadata.item();

    final startEvent = maybeCreateOpenAIToolInputStartEvent(
      toolState: toolState,
      fallbackToolCallId: resolvedToolCallId,
      metadata: itemMetadata,
    );
    if (startEvent != null) {
      yield startEvent;
    }

    final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
      toolState: toolState,
      fallbackToolCallId: resolvedToolCallId,
      delta: deltaResult.argumentsDelta,
      metadata: itemMetadata,
    );
    if (deltaEvent != null) {
      yield deltaEvent;
    }
  }

  Iterable<TextStreamEvent> _handleOutputTextAnnotationAddedChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
  ) sync* {
    final annotation = _asMap(chunk['annotation']);
    final sourceEvent = decodeOpenAIResponsesSourceEvent(
      annotation,
      emittedAnnotationKeys: state.emittedAnnotationKeys,
    );
    if (sourceEvent != null) {
      yield sourceEvent;
    }
  }

  Iterable<TextStreamEvent> _handleContentPartDoneChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final part = _asMap(chunk['part']);
    if (part == null || _asString(part['type']) != 'output_text') {
      return;
    }

    appendOpenAILogprobs(
      state.logprobs,
      _jsonListOrNull(part['logprobs']),
    );

    for (final rawAnnotation in _asList(part['annotations'])) {
      final annotation = _asMap(rawAnnotation);
      final sourceEvent = decodeOpenAIResponsesSourceEvent(
        annotation,
        emittedAnnotationKeys: state.emittedAnnotationKeys,
      );
      if (sourceEvent != null) {
        yield sourceEvent;
      }
    }

    final textId = _resolveTextId(chunk, null);
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

  Iterable<TextStreamEvent> _handlePartialImageChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    yield CustomEvent(
      kind: 'openai.image_generation_call.partial_image',
      data: {
        'item_id': _asString(chunk['item_id']),
        'output_index': _asInt(chunk['output_index']),
        'partial_image_b64': _asString(chunk['partial_image_b64']),
      },
      providerMetadata: metadata.custom({
        'responseId': state.responseId,
        'itemId': _asString(chunk['item_id']),
        'itemType': 'image_generation_call.partial_image',
        'outputIndex': _asInt(chunk['output_index']),
        'serviceTier': state.serviceTier,
      }),
    );
  }

  Iterable<TextStreamEvent> _handleOutputItemDoneChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final item = _asMap(chunk['item']);
    if (item == null) {
      return;
    }

    final itemType = _asString(item['type']);
    final providerMetadata = metadata.item(item);

    if (itemType == 'message') {
      final textId = _resolveTextId(chunk, item);
      final textEndEvent = maybeCreateOpenAITextEndEvent(
        state: state.textParts,
        id: textId,
        metadata: () => providerMetadata,
        allowUnstarted: true,
      );
      if (textEndEvent != null) {
        yield textEndEvent;
      }
      return;
    }

    if (itemType == 'function_call') {
      final outputIndex = _asInt(chunk['output_index']);
      var toolState =
          outputIndex == null ? null : state.toolCalls.remove(outputIndex);
      final fallbackToolCallId =
          _asString(item['call_id']) ?? _asString(chunk['item_id']) ?? 'tool';

      if (toolState != null) {
        toolState.update(
          toolCallId: _asString(item['call_id']),
          toolName: _asString(item['name']),
          title: _asString(item['title']),
        );
        state.hasToolCalls = true;
      } else {
        toolState = resolveOpenAIStreamToolCallState(
          state: state,
          index: null,
          fallbackToolCallId: fallbackToolCallId,
          toolCallId: _asString(item['call_id']),
          toolName: _asString(item['name']),
          title: _asString(item['title']),
          createEphemeralWhenIndexMissing: true,
        );
      }

      final resolvedToolCallId =
          toolState.resolveToolCallId(fallbackToolCallId);
      final resolvedToolName = toolState.resolveToolName();

      final startEvent = maybeCreateOpenAIToolInputStartEvent(
        toolState: toolState,
        fallbackToolCallId: resolvedToolCallId,
        title: _asString(item['title']),
        metadata: () => providerMetadata,
      );
      if (startEvent != null) {
        yield startEvent;
      }

      final encodedArguments = resolveOpenAIResponsesFunctionCallArguments(
        item,
        fallbackArguments: toolState.arguments.toString(),
      );
      final resolvedInput = resolveOpenAIStreamToolInput(
        toolState: toolState,
        fallbackToolCallId: resolvedToolCallId,
        fallbackToolName: resolvedToolName,
        encodedArguments: encodedArguments,
      );
      if (resolvedInput.decodeError != null) {
        yield createOpenAIToolInputErrorEvent(
          input: resolvedInput,
          metadata: () => providerMetadata,
        );
        return;
      }

      final endEvent = maybeCreateOpenAIToolInputEndEvent(
        toolState: toolState,
        fallbackToolCallId: resolvedToolCallId,
        metadata: () => providerMetadata,
      );
      if (endEvent != null) {
        yield endEvent;
      }

      final toolCallPart = decodeOpenAIResponsesFunctionCallOutput(
        item,
        fallbackToolCallId: resolvedToolCallId,
        fallbackArguments: toolState.arguments.toString(),
        fallbackToolName: resolvedToolName,
        decodedInput: resolvedInput.decodedInput,
      );
      if (toolCallPart != null) {
        yield ToolCallEvent(
          toolCall: toolCallPart.toolCall,
          providerMetadata: toolCallPart.providerMetadata,
        );
      }
      return;
    }

    if (itemType == 'mcp_approval_request') {
      final approvalId =
          _asString(item['approval_request_id']) ?? _asString(item['id']);
      final toolName = _asString(item['name']);
      if (approvalId == null || toolName == null) {
        return;
      }

      state.hasToolCalls = true;
      final providerMetadata = openAIResponsesItemMetadata(
        item,
        extra: {
          'approvalRequestId': approvalId,
          'serverLabel': _asString(item['server_label']),
        },
      );
      final qualifiedToolName = 'mcp.$toolName';

      yield ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: approvalId,
          toolName: qualifiedToolName,
          input: decodeOpenAIResponsesJsonValue(
            _asString(item['arguments']) ?? '{}',
          ),
          providerExecuted: true,
          isDynamic: true,
          title: _asString(item['server_label']),
        ),
        providerMetadata: providerMetadata,
      );
      yield ToolApprovalRequestEvent(
        approvalId: approvalId,
        toolCallId: approvalId,
        providerMetadata: providerMetadata,
      );
      return;
    }

    if (itemType == 'mcp_call') {
      final toolCallId =
          _asString(item['approval_request_id']) ?? _asString(item['id']);
      final toolName = _asString(item['name']);
      if (toolCallId == null || toolName == null) {
        return;
      }

      state.hasToolCalls = true;
      final providerMetadata = openAIResponsesItemMetadata(
        item,
        extra: {
          'approvalRequestId': _asString(item['approval_request_id']),
          'serverLabel': _asString(item['server_label']),
        },
      );
      final qualifiedToolName = 'mcp.$toolName';
      final arguments = decodeOpenAIResponsesJsonValue(
        _asString(item['arguments']) ?? '{}',
      );

      yield ToolCallEvent(
        toolCall: ToolCallContent(
          toolCallId: toolCallId,
          toolName: qualifiedToolName,
          input: arguments,
          providerExecuted: true,
          isDynamic: true,
          title: _asString(item['server_label']),
        ),
        providerMetadata: providerMetadata,
      );
      yield ToolResultEvent(
        toolResult: ToolResultContent(
          toolCallId: toolCallId,
          toolName: qualifiedToolName,
          output: {
            'type': 'mcp_call',
            'serverLabel': _asString(item['server_label']),
            'name': toolName,
            'arguments': arguments,
            if (item['output'] != null) 'output': item['output'],
            if (item['error'] != null) 'error': item['error'],
          },
          isError: item['error'] != null,
          isDynamic: true,
        ),
        providerMetadata: providerMetadata,
      );
      return;
    }

    if (itemType != 'reasoning' && itemType != null) {
      yield CustomEvent(
        kind: 'openai.$itemType',
        data: item,
        providerMetadata: providerMetadata,
      );
    }
  }

  Iterable<TextStreamEvent> _handleErrorChunk(
    Map<String, Object?> chunk,
  ) sync* {
    yield ErrorEvent(
      ModelError.fromUnknown(
        chunk['error'] ?? chunk,
        kind: ModelErrorKind.provider,
      ),
    );
  }

  Iterable<TextStreamEvent> _handleTerminalResponseChunk(
    String chunkType,
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
    _ResponsesStreamMetadataAdapter metadata,
  ) sync* {
    final response = _asMap(chunk['response']);
    if (response == null) {
      return;
    }

    captureOpenAIResponseMetadata(
      state: state,
      responseId: _asString(response['id']),
      responseTimestamp: _decodeResponseTimestamp(response),
      responseModelId: _asString(response['model']),
      serviceTier: _asString(response['service_tier']),
      rawFinishReason: _responseFinishReason(response),
      usage: _decodeUsage(_asMap(response['usage'])),
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
      finishReason: _mapFinishReason(
        rawReason: state.rawFinishReason,
        hasToolCalls: state.hasToolCalls,
        status: chunkType == 'response.failed'
            ? 'failed'
            : _asString(response['status']),
      ),
      rawFinishReason: state.rawFinishReason,
      usage: state.usage,
      providerMetadata: metadata.response(
        response,
        logprobs: state.logprobs,
      ),
    );
  }
}

final class _ResponsesStreamMetadataAdapter {
  final OpenAIResponsesStreamState state;
  final Map<String, Object?> chunk;
  final ProviderMetadata? Function(Map<String, Object?> values)
      customMetadataBuilder;

  const _ResponsesStreamMetadataAdapter({
    required this.state,
    required this.chunk,
    required this.customMetadataBuilder,
  });

  ProviderMetadata? item([Map<String, Object?>? item]) =>
      openAIResponsesStreamItemMetadata(
        responseId: state.responseId,
        serviceTier: state.serviceTier,
        chunk: chunk,
        item: item,
      );

  ProviderMetadata? textPart(Map<String, Object?> part) =>
      openAIResponsesStreamTextPartMetadata(
        responseId: state.responseId,
        serviceTier: state.serviceTier,
        chunk: chunk,
        part: part,
      );

  ProviderMetadata? response(
    Map<String, Object?> response, {
    List<Object?>? logprobs,
  }) =>
      openAIResponsesResponseMetadata(
        response,
        logprobs: logprobs ?? const [],
      );

  ProviderMetadata? custom(Map<String, Object?> values) =>
      customMetadataBuilder(values);
}
