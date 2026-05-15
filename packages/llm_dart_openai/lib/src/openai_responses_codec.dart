import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_options.dart';
import 'openai_responses_request_codec.dart';
import 'openai_responses_support.dart';
import 'openai_streaming_support.dart';

final class OpenAIResponsesStreamState extends OpenAIStreamState {
  final Set<String> emittedAnnotationKeys = {};
}

final class OpenAIResponsesCodec {
  const OpenAIResponsesCodec();

  OpenAIResponsesRequest encodeRequest({
    required String modelId,
    required List<PromptMessage> prompt,
    required List<FunctionToolDefinition> tools,
    required ToolChoice? toolChoice,
    required GenerateTextOptions options,
    required OpenAIGenerateTextOptions providerOptions,
    required bool stream,
  }) {
    return const OpenAIResponsesRequestCodec().encodeRequest(
      modelId: modelId,
      prompt: prompt,
      tools: tools,
      toolChoice: toolChoice,
      options: options,
      providerOptions: providerOptions,
      stream: stream,
    );
  }

  GenerateTextResult decodeGenerateResponse(
    Map<String, Object?> response, {
    List<ModelWarning> warnings = const [],
  }) =>
      _decodeGenerateResponse(response, warnings: warnings);

  Iterable<LanguageModelStreamEvent> decodeStreamChunk(
    Map<String, Object?> chunk,
    OpenAIResponsesStreamState state,
  ) sync* {
    final chunkType = _asString(chunk['type']);
    if (chunkType == null) {
      return;
    }
    final metadata = _ResponsesStreamMetadataAdapter(
      state: state,
      chunk: chunk,
      customMetadataBuilder: openAIResponsesProviderMetadata,
    );

    switch (chunkType) {
      case 'response.created':
        yield* _handleResponseCreatedChunk(chunk, state, metadata);
        return;
      case 'response.output_item.added':
        yield* _handleOutputItemAddedChunk(chunk, state, metadata);
        return;
      case 'response.output_text.delta':
        yield* _handleOutputTextDeltaChunk(chunk, state, metadata);
        return;
      case 'response.output_text.done':
        yield* _handleOutputTextDoneChunk(chunk, state, metadata);
        return;
      case 'response.reasoning_summary_part.added':
        yield* _handleReasoningSummaryPartAddedChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.reasoning_summary_text.delta':
        yield* _handleReasoningSummaryTextDeltaChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.reasoning_summary_part.done':
        yield* _handleReasoningSummaryPartDoneChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.function_call_arguments.delta':
        yield* _handleFunctionCallArgumentsDeltaChunk(
          chunk,
          state,
          metadata,
        );
        return;
      case 'response.output_text.annotation.added':
        yield* _handleOutputTextAnnotationAddedChunk(chunk, state);
        return;
      case 'response.content_part.done':
        yield* _handleContentPartDoneChunk(chunk, state, metadata);
        return;
      case 'response.image_generation_call.partial_image':
        yield* _handlePartialImageChunk(chunk, state, metadata);
        return;
      case 'response.output_item.done':
        yield* _handleOutputItemDoneChunk(chunk, state, metadata);
        return;
      case 'response.completed':
      case 'response.incomplete':
      case 'response.failed':
        yield* _handleTerminalResponseChunk(
          chunkType,
          chunk,
          state,
          metadata,
        );
        return;
      case 'error':
        yield* _handleErrorChunk(chunk);
        return;
    }
  }

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

  Iterable<LanguageModelStreamEvent> _handleResponseCreatedChunk(
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

  Iterable<LanguageModelStreamEvent> _handleOutputItemAddedChunk(
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

  Iterable<LanguageModelStreamEvent> _handleOutputTextDeltaChunk(
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

  Iterable<LanguageModelStreamEvent> _handleOutputTextDoneChunk(
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

  Iterable<LanguageModelStreamEvent> _handleReasoningSummaryPartAddedChunk(
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

  Iterable<LanguageModelStreamEvent> _handleReasoningSummaryTextDeltaChunk(
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

  Iterable<LanguageModelStreamEvent> _handleReasoningSummaryPartDoneChunk(
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

  Iterable<LanguageModelStreamEvent> _handleFunctionCallArgumentsDeltaChunk(
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

  Iterable<LanguageModelStreamEvent> _handleOutputTextAnnotationAddedChunk(
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

  Iterable<LanguageModelStreamEvent> _handleContentPartDoneChunk(
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

  Iterable<LanguageModelStreamEvent> _handlePartialImageChunk(
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

  Iterable<LanguageModelStreamEvent> _handleOutputItemDoneChunk(
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
          toolOutput: ToolOutput.fromValue(
            {
              'type': 'mcp_call',
              'serverLabel': _asString(item['server_label']),
              'name': toolName,
              'arguments': arguments,
              if (item['output'] != null) 'output': item['output'],
              if (item['error'] != null) 'error': item['error'],
            },
            isError: item['error'] != null,
          ),
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

  Iterable<LanguageModelStreamEvent> _handleErrorChunk(
    Map<String, Object?> chunk,
  ) sync* {
    yield ErrorEvent(
      ModelError.fromUnknown(
        chunk['error'] ?? chunk,
        kind: ModelErrorKind.provider,
      ),
    );
  }

  Iterable<LanguageModelStreamEvent> _handleTerminalResponseChunk(
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

  String _resolveTextId(
    Map<String, Object?> chunk,
    Map<String, Object?>? item,
  ) {
    return _asString(chunk['item_id']) ??
        _asString(item?['id']) ??
        'text-${_asInt(chunk['output_index']) ?? 0}';
  }

  String _resolveReasoningId(Map<String, Object?> chunk) {
    return '${_asString(chunk['item_id']) ?? 'reasoning'}:${_asInt(chunk['summary_index']) ?? 0}';
  }

  Map<String, Object?>? _asMap(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }

    if (value is Map) {
      return Map<String, Object?>.from(value);
    }

    return null;
  }

  List<Object?> _asList(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return const [];
  }

  List<Object?>? _jsonListOrNull(Object? value) {
    if (value is List<Object?>) {
      return value;
    }

    if (value is List) {
      return List<Object?>.from(value);
    }

    return null;
  }

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  DateTime? _decodeResponseTimestamp(Map<String, Object?> response) {
    final createdAt = _asInt(response['created_at']);
    if (createdAt == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
      isUtc: true,
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
