import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_request_encoding_util.dart';
import 'openai_responses_tool_output_projection.dart';
import 'openai_tool_output_encoding.dart';

final class OpenAIResponsesCustomToolCallReplayProjection {
  final Map<String, Object?> inputItem;

  const OpenAIResponsesCustomToolCallReplayProjection(this.inputItem);
}

final class OpenAIResponsesCustomToolOutputReplayProjection {
  final Map<String, Object?> inputItem;

  const OpenAIResponsesCustomToolOutputReplayProjection(this.inputItem);
}

OpenAIResponsesCustomToolCallReplayProjection?
    projectOpenAIResponsesCustomToolReplayCall(
  ToolCallPromptPart part, {
  required bool Function(String toolName) isCustomToolName,
}) {
  if (!isCustomToolName(part.toolName)) {
    return null;
  }

  final itemId = _replayItemId(part);
  return OpenAIResponsesCustomToolCallReplayProjection({
    'type': 'custom_tool_call',
    'call_id': part.toolCallId,
    'name': part.toolName,
    'input': _encodeCustomToolInput(part.input),
    if (itemId != null) 'id': itemId,
  });
}

OpenAIResponsesCustomToolOutputReplayProjection?
    projectOpenAIResponsesCustomToolReplayOutput(
  ToolResultPromptPart part, {
  required bool Function(String toolName) isCustomToolName,
  OpenAIResponsesToolOutputProjection toolOutputProjection =
      const OpenAIResponsesToolOutputProjection(),
}) {
  if (!isCustomToolName(part.toolName)) {
    return null;
  }

  return OpenAIResponsesCustomToolOutputReplayProjection({
    'type': 'custom_tool_call_output',
    'call_id': part.toolCallId,
    'output': _encodeCustomToolOutput(
      part.toolOutput,
      toolOutputProjection: toolOutputProjection,
    ),
  });
}

String _encodeCustomToolInput(Object? input) {
  if (input == null) {
    return '';
  }

  if (input is String) {
    return input;
  }

  return jsonEncode(normalizeJsonValue(input, path: r'$.toolCall.input'));
}

Object? _encodeCustomToolOutput(
  ToolOutput output, {
  required OpenAIResponsesToolOutputProjection toolOutputProjection,
}) {
  if (output is ContentToolOutput) {
    return toolOutputProjection.encode(output);
  }

  if (output is ExecutionDeniedToolOutput) {
    return output.reason ?? 'Tool call execution denied.';
  }

  if (output.value == null) {
    return output.isError ? 'Tool execution failed' : 'null';
  }

  if (output.value is String) {
    return output.value;
  }

  return encodeOpenAIToolOutputAsText(output);
}

String? _replayItemId(PromptPart part) {
  final metadata = openAIPromptPartProviderMetadata(part)?.namespace('openai');
  return openAIRequestAsString(metadata?['itemId']);
}
