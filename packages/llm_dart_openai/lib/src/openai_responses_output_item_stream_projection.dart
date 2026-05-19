import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_stream_projection.dart';
import 'openai_responses_custom_stream_projection.dart';
import 'openai_responses_image_generation_stream_projection.dart';
import 'openai_responses_mcp_stream_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_tool_codec.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_text_reasoning_stream_projection.dart';
import 'openai_responses_tool_search_stream_projection.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesOutputItemAddedChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final item = openAIResponsesAsMap(chunk['item']);
  if (item == null) {
    return;
  }

  final itemType = openAIResponsesAsString(item['type']);

  if (itemType == 'message') {
    yield* decodeOpenAIResponsesMessageItemAdded(
      chunk,
      item,
      state,
      metadata,
    );
    return;
  }

  if (itemType == 'function_call') {
    yield* decodeOpenAIResponsesFunctionCallItemAdded(
      chunk,
      item,
      state,
      metadata,
    );
    return;
  }

  if (itemType == 'code_interpreter_call') {
    yield* decodeOpenAIResponsesCodeInterpreterItemAddedChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'image_generation_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesImageGenerationItemAddedChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'tool_search_call') {
    yield* decodeOpenAIResponsesToolSearchCallItemAddedChunk(
      chunk,
      item,
      state,
    );
  }
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesOutputItemDoneChunk(
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
    yield* decodeOpenAIResponsesMessageItemDone(
      chunk,
      item,
      state,
      metadata,
    );
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
    yield* decodeOpenAIResponsesMcpApprovalRequestItemDone(item);
    return;
  }

  if (itemType == 'mcp_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesMcpCallItemDone(item);
    return;
  }

  if (itemType == 'code_interpreter_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesCodeInterpreterItemDoneChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'image_generation_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesImageGenerationItemDoneChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'tool_search_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesToolSearchCallItemDoneChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'tool_search_output') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesToolSearchOutputItemDoneChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  yield* decodeOpenAIResponsesCustomOutputItemDone(
    itemType,
    item,
    providerMetadata,
  );
}
