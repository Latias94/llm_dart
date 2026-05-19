import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_projected_tool_models.dart';

ToolCallContent googleProjectedToolCallContent(GoogleProjectedToolCall call) {
  return ToolCallContent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    input: call.input,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
  );
}

ToolResultContent googleProjectedToolResultContent(
  GoogleProjectedToolResult result,
) {
  return ToolResultContent(
    toolCallId: result.toolCallId,
    toolName: result.toolName,
    toolOutput: result.toolOutput,
    isDynamic: result.isDynamic,
  );
}

ToolCallContentPart googleProjectedToolCallContentPart(
  GoogleProjectedToolCall call,
) {
  return ToolCallContentPart(
    googleProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

ToolResultContentPart googleProjectedToolResultContentPart(
  GoogleProjectedToolResult result,
) {
  return ToolResultContentPart(
    googleProjectedToolResultContent(result),
    providerMetadata: result.providerMetadata,
  );
}

Iterable<LanguageModelStreamEvent> emitGoogleProjectedToolCallEvents(
  GoogleProjectedToolCall call,
) sync* {
  yield ToolInputStartEvent(
    toolCallId: call.toolCallId,
    toolName: call.toolName,
    providerExecuted: call.providerExecuted,
    isDynamic: call.isDynamic,
    providerMetadata: call.providerMetadata,
  );
  yield ToolInputDeltaEvent(
    toolCallId: call.toolCallId,
    delta: call.encodedInput,
    providerMetadata: call.providerMetadata,
  );
  yield ToolInputEndEvent(
    toolCallId: call.toolCallId,
    providerMetadata: call.providerMetadata,
  );
  yield ToolCallEvent(
    toolCall: googleProjectedToolCallContent(call),
    providerMetadata: call.providerMetadata,
  );
}

ToolResultEvent googleProjectedToolResultEvent(
  GoogleProjectedToolResult result,
) {
  return ToolResultEvent(
    toolResult: googleProjectedToolResultContent(result),
    providerMetadata: result.providerMetadata,
  );
}
