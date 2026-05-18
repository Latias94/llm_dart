import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_custom_stream_projection.dart';
import 'openai_responses_output_item_stream_projection.dart';
import 'openai_responses_source_annotation_stream_projection.dart';
import 'openai_responses_stream_result_codec.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_tool_codec.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_support.dart';
import 'openai_responses_text_reasoning_stream_projection.dart';

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
      yield* decodeOpenAIResponsesOutputItemAddedChunk(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.output_text.delta':
      yield* decodeOpenAIResponsesOutputTextDeltaChunk(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.output_text.done':
      yield* decodeOpenAIResponsesOutputTextDoneChunk(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.reasoning_summary_part.added':
      yield* decodeOpenAIResponsesReasoningSummaryPartAddedChunk(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.reasoning_summary_text.delta':
      yield* decodeOpenAIResponsesReasoningSummaryTextDeltaChunk(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.reasoning_summary_part.done':
      yield* decodeOpenAIResponsesReasoningSummaryPartDoneChunk(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.function_call_arguments.delta':
      yield* decodeOpenAIResponsesFunctionCallArgumentsDelta(
        chunk,
        state,
        metadata,
      );
      return;
    case 'response.output_text.annotation.added':
      yield* decodeOpenAIResponsesOutputTextAnnotationAddedChunk(chunk, state);
      return;
    case 'response.content_part.done':
      yield* decodeOpenAIResponsesContentPartDoneChunk(chunk, state, metadata);
      return;
    case 'response.image_generation_call.partial_image':
      yield* decodeOpenAIResponsesPartialImageChunk(chunk, state);
      return;
    case 'response.output_item.done':
      yield* decodeOpenAIResponsesOutputItemDoneChunk(chunk, state, metadata);
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
