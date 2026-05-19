import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_apply_patch_stream_projection.dart';
import 'openai_responses_code_interpreter_stream_projection.dart';
import 'openai_responses_computer_use_stream_projection.dart';
import 'openai_responses_custom_tool_stream_projection.dart';
import 'openai_responses_file_search_stream_projection.dart';
import 'openai_responses_image_generation_stream_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_tool_codec.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_text_reasoning_stream_projection.dart';
import 'openai_responses_tool_search_stream_projection.dart';
import 'openai_responses_web_search_stream_projection.dart';

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

  if (itemType == 'custom_tool_call') {
    yield* decodeOpenAIResponsesCustomToolCallItemAddedChunk(
      chunk,
      item,
      state,
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

  if (itemType == 'file_search_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesFileSearchItemAddedChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'web_search_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesWebSearchItemAddedChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'computer_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesComputerUseItemAddedChunk(
      chunk,
      item,
      state,
    );
    return;
  }

  if (itemType == 'apply_patch_call') {
    state.hasToolCalls = true;
    yield* decodeOpenAIResponsesApplyPatchItemAddedChunk(
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
