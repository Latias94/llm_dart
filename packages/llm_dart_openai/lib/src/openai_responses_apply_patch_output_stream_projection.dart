import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_shell_projection.dart';
import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesApplyPatchOutputItemDoneChunk(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
) sync* {
  final projection = projectOpenAIResponsesApplyPatchOutput(
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
