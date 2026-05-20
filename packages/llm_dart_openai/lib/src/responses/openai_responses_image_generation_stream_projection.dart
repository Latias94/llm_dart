import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_image_generation_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesImageGenerationItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesImageGenerationCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesImageGenerationItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesImageGenerationCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesImageGenerationPartialImageChunk(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesImageGenerationPartialImage(
    chunk: chunk,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
  );

  yield ToolResultEvent(
    toolResult: projection.toToolResult(preliminary: true),
    providerMetadata: projection.providerMetadata,
  );
}
