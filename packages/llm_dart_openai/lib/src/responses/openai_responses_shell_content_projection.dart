import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_content_part_support.dart';
import 'openai_responses_shell_projection.dart';

ToolCallContentPart? decodeOpenAIResponsesLocalShellCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesLocalShellCall(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesLocalShellCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesLocalShellOutput(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesShellCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesShellCall(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesShellCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesShellOutput(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolCallContentPart? decodeOpenAIResponsesApplyPatchCallOutput(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesApplyPatchCall(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolCallContentPart(
    projection.toToolCall(),
    providerMetadata: projection.providerMetadata,
  );
}

ToolResultContentPart? decodeOpenAIResponsesApplyPatchCallOutputItem(
  Map<String, Object?> item,
) {
  final projection = projectOpenAIResponsesApplyPatchOutput(item);
  if (projection == null) {
    return null;
  }

  return openAIResponsesToolResultContentPart(
    projection.toToolResult(),
    providerMetadata: projection.providerMetadata,
  );
}
