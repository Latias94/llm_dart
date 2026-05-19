import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_content_part_support.dart';
import 'openai_responses_custom_tool_projection.dart';

ToolCallContentPart? decodeOpenAIResponsesCustomToolCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesCustomToolCall(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesCustomToolCallOutputItem(
  Map<String, Object?> item, {
  String? fallbackToolName,
}) {
  final projection = projectOpenAIResponsesCustomToolOutput(
    item,
    fallbackToolName: fallbackToolName,
  );
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
