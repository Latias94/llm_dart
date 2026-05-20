import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_content_part_support.dart';
import 'openai_responses_tool_search_projection.dart';

ToolCallContentPart? decodeOpenAIResponsesToolSearchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesToolSearchCall(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesToolSearchOutput(
  Map<String, Object?> item, {
  String? fallbackToolCallId,
}) {
  final projection = projectOpenAIResponsesToolSearchOutput(
    item,
    fallbackToolCallId: fallbackToolCallId,
  );
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
