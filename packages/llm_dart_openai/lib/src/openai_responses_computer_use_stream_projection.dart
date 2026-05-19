import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_computer_use_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesComputerUseItemAddedChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesComputerUseCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolInputStartEvent(
    toolCallId: projection.toolCallId,
    toolName: openAIResponsesComputerUseToolName,
    providerExecuted: true,
    providerMetadata: projection.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesComputerUseItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesComputerUseCall(
    item,
    responseId: state.responseId,
    serviceTier: state.serviceTier,
    outputIndex: openAIResponsesAsInt(chunk['output_index']),
  );
  if (projection == null) {
    return;
  }

  yield ToolInputEndEvent(
    toolCallId: projection.toolCallId,
    providerMetadata: projection.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
  yield ToolResultEvent(
    toolResult: projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
