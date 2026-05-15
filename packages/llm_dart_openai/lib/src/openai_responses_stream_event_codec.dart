import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_result_codec.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_tool_codec.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_support.dart';
import 'openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesStreamChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  final chunkType = openAIResponsesAsString(chunk['type']);
  if (chunkType == null) {
    return;
  }
  final metadata = OpenAIResponsesStreamMetadataAdapter(
    state: state,
    chunk: chunk,
    customMetadataBuilder: openAIResponsesProviderMetadata,
  );

  switch (chunkType) {
    case 'response.created':
      yield* decodeOpenAIResponsesCreatedChunk(chunk, state, metadata);
      return;
    case 'response.output_item.added':
      yield* _decodeOutputItemAddedChunk(chunk, state, metadata);
      return;
    case 'response.output_text.delta':
      yield* _decodeOutputTextDeltaChunk(chunk, state, metadata);
      return;
    case 'response.output_text.done':
      yield* _decodeOutputTextDoneChunk(chunk, state, metadata);
      return;
    case 'response.reasoning_summary_part.added':
      yield* _decodeReasoningSummaryPartAddedChunk(chunk, state, metadata);
      return;
    case 'response.reasoning_summary_text.delta':
      yield* _decodeReasoningSummaryTextDeltaChunk(chunk, state, metadata);
      return;
    case 'response.reasoning_summary_part.done':
      yield* _decodeReasoningSummaryPartDoneChunk(chunk, state, metadata);
      return;
    case 'response.function_call_arguments.delta':
      yield* decodeOpenAIResponsesFunctionCallArgumentsDelta(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.output_text.annotation.added':
      yield* _decodeOutputTextAnnotationAddedChunk(chunk, state);
      return;
    case 'response.content_part.done':
      yield* _decodeContentPartDoneChunk(chunk, state, metadata);
      return;
    case 'response.image_generation_call.partial_image':
      yield* _decodePartialImageChunk(chunk, state, metadata);
      return;
    case 'response.output_item.done':
      yield* _decodeOutputItemDoneChunk(chunk, state, metadata);
      return;
    case 'response.completed':
    case 'response.incomplete':
    case 'response.failed':
      yield* decodeOpenAIResponsesTerminalChunk(
        chunkType,
        chunk,
        state,
        metadata,
      );
      return;
    case 'error':
      yield* decodeOpenAIResponsesErrorChunk(chunk);
      return;
  }
}

Iterable<LanguageModelStreamEvent> _decodeOutputItemAddedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final item = openAIResponsesAsMap(chunk['item']);
  if (item == null) {
    return;
  }

  final itemType = openAIResponsesAsString(item['type']);
  final providerMetadata = metadata.item(item);

  if (itemType == 'message') {
    final textId = openAIResponsesResolveTextId(chunk, item);
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
    yield* decodeOpenAIResponsesFunctionCallItemAdded(
      chunk,
      item,
      state,
      metadata,
    );
  }
}

Iterable<LanguageModelStreamEvent> _decodeOutputTextDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final textId = openAIResponsesResolveTextId(chunk, null);
  yield* decodeOpenAITextDeltaEvents(
    state: state.textParts,
    id: textId,
    delta: openAIResponsesAsString(chunk['delta']),
    aggregateLogprobs: state.logprobs,
    deltaLogprobs: openAIResponsesJsonListOrNull(chunk['logprobs']),
    startMetadata: metadata.item,
    deltaMetadata: metadata.item,
  );
}

Iterable<LanguageModelStreamEvent> _decodeOutputTextDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final textId = openAIResponsesResolveTextId(chunk, null);
  final textEndEvent = maybeCreateOpenAITextEndEvent(
    state: state.textParts,
    id: textId,
    metadata: metadata.item,
  );
  if (textEndEvent != null) {
    yield textEndEvent;
  }
}

Iterable<LanguageModelStreamEvent> _decodeReasoningSummaryPartAddedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final reasoningStartEvent = maybeCreateOpenAIReasoningStartEvent(
    state: state.reasoningParts,
    id: openAIResponsesResolveReasoningId(chunk),
    metadata: metadata.item,
  );
  if (reasoningStartEvent != null) {
    yield reasoningStartEvent;
  }
}

Iterable<LanguageModelStreamEvent> _decodeReasoningSummaryTextDeltaChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  yield* decodeOpenAIReasoningDeltaEvents(
    state: state.reasoningParts,
    id: openAIResponsesResolveReasoningId(chunk),
    delta: openAIResponsesAsString(chunk['delta']),
    startMetadata: metadata.item,
    deltaMetadata: metadata.item,
  );
}

Iterable<LanguageModelStreamEvent> _decodeReasoningSummaryPartDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final reasoningEndEvent = maybeCreateOpenAIReasoningEndEvent(
    state: state.reasoningParts,
    id: openAIResponsesResolveReasoningId(chunk),
    metadata: metadata.item,
  );
  if (reasoningEndEvent != null) {
    yield reasoningEndEvent;
  }
}

Iterable<LanguageModelStreamEvent> _decodeOutputTextAnnotationAddedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  final annotation = openAIResponsesAsMap(chunk['annotation']);
  final sourceEvent = decodeOpenAIResponsesSourceEvent(
    annotation,
    emittedAnnotationKeys: state.emittedAnnotationKeys,
  );
  if (sourceEvent != null) {
    yield sourceEvent;
  }
}

Iterable<LanguageModelStreamEvent> _decodeContentPartDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final part = openAIResponsesAsMap(chunk['part']);
  if (part == null || openAIResponsesAsString(part['type']) != 'output_text') {
    return;
  }

  appendOpenAILogprobs(
    state.logprobs,
    openAIResponsesJsonListOrNull(part['logprobs']),
  );

  for (final rawAnnotation in openAIResponsesAsList(part['annotations'])) {
    final annotation = openAIResponsesAsMap(rawAnnotation);
    final sourceEvent = decodeOpenAIResponsesSourceEvent(
      annotation,
      emittedAnnotationKeys: state.emittedAnnotationKeys,
    );
    if (sourceEvent != null) {
      yield sourceEvent;
    }
  }

  final textId = openAIResponsesResolveTextId(chunk, null);
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

Iterable<LanguageModelStreamEvent> _decodePartialImageChunk(
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

Iterable<LanguageModelStreamEvent> _decodeOutputItemDoneChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final item = openAIResponsesAsMap(chunk['item']);
  if (item == null) {
    return;
  }

  final itemType = openAIResponsesAsString(item['type']);
  final providerMetadata = metadata.item(item);

  if (itemType == 'message') {
    final textId = openAIResponsesResolveTextId(chunk, item);
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
    yield* decodeOpenAIResponsesFunctionCallItemDone(
      chunk,
      item,
      state,
      metadata,
    );
    return;
  }

  if (itemType == 'mcp_approval_request') {
    state.hasToolCalls = true;
    yield* _decodeMcpApprovalRequestItemDone(item);
    return;
  }

  if (itemType == 'mcp_call') {
    state.hasToolCalls = true;
    yield* _decodeMcpCallItemDone(item);
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

Iterable<LanguageModelStreamEvent> _decodeMcpApprovalRequestItemDone(
  Map<String, Object?> item,
) sync* {
  final approvalId = openAIResponsesAsString(item['approval_request_id']) ??
      openAIResponsesAsString(item['id']);
  final toolName = openAIResponsesAsString(item['name']);
  if (approvalId == null || toolName == null) {
    return;
  }

  final providerMetadata = openAIResponsesItemMetadata(
    item,
    extra: {
      'approvalRequestId': approvalId,
      'serverLabel': openAIResponsesAsString(item['server_label']),
    },
  );
  final qualifiedToolName = 'mcp.$toolName';

  yield ToolCallEvent(
    toolCall: ToolCallContent(
      toolCallId: approvalId,
      toolName: qualifiedToolName,
      input: decodeOpenAIResponsesJsonValue(
        openAIResponsesAsString(item['arguments']) ?? '{}',
      ),
      providerExecuted: true,
      isDynamic: true,
      title: openAIResponsesAsString(item['server_label']),
    ),
    providerMetadata: providerMetadata,
  );
  yield ToolApprovalRequestEvent(
    approvalId: approvalId,
    toolCallId: approvalId,
    providerMetadata: providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> _decodeMcpCallItemDone(
  Map<String, Object?> item,
) sync* {
  final toolCallId = openAIResponsesAsString(item['approval_request_id']) ??
      openAIResponsesAsString(item['id']);
  final toolName = openAIResponsesAsString(item['name']);
  if (toolCallId == null || toolName == null) {
    return;
  }

  final providerMetadata = openAIResponsesItemMetadata(
    item,
    extra: {
      'approvalRequestId': openAIResponsesAsString(
        item['approval_request_id'],
      ),
      'serverLabel': openAIResponsesAsString(item['server_label']),
    },
  );
  final qualifiedToolName = 'mcp.$toolName';
  final arguments = decodeOpenAIResponsesJsonValue(
    openAIResponsesAsString(item['arguments']) ?? '{}',
  );

  yield ToolCallEvent(
    toolCall: ToolCallContent(
      toolCallId: toolCallId,
      toolName: qualifiedToolName,
      input: arguments,
      providerExecuted: true,
      isDynamic: true,
      title: openAIResponsesAsString(item['server_label']),
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
          'serverLabel': openAIResponsesAsString(item['server_label']),
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
}
