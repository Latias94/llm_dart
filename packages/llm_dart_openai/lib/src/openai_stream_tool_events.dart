import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_stream_tool_input_projection.dart';
import 'openai_streaming_support.dart';

ToolInputStartEvent? maybeCreateOpenAIToolInputStartEvent({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  String fallbackToolName = 'function',
  String? title,
  required ProviderMetadata? Function() metadata,
  bool providerExecuted = false,
  bool isDynamic = false,
}) {
  if (toolState.startEmitted) {
    return null;
  }

  toolState.startEmitted = true;
  return ToolInputStartEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    toolName: toolState.resolveToolName(fallbackToolName),
    providerExecuted: providerExecuted,
    isDynamic: isDynamic,
    title: title ?? toolState.title,
    providerMetadata: metadata(),
  );
}

ToolInputDeltaEvent? maybeCreateOpenAIToolInputDeltaEvent({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  required String? delta,
  required ProviderMetadata? Function() metadata,
}) {
  if (delta == null || delta.isEmpty) {
    return null;
  }

  return ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    delta: delta,
    providerMetadata: metadata(),
  );
}

ToolInputEndEvent? maybeCreateOpenAIToolInputEndEvent({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  required ProviderMetadata? Function() metadata,
}) {
  if (toolState.endEmitted) {
    return null;
  }

  toolState.endEmitted = true;
  return ToolInputEndEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    providerMetadata: metadata(),
  );
}

ToolInputErrorEvent createOpenAIToolInputErrorEvent({
  required OpenAIResolvedToolInput input,
  required ProviderMetadata? Function() metadata,
  bool providerExecuted = false,
  bool isDynamic = false,
}) {
  return ToolInputErrorEvent(
    toolCallId: input.toolCallId,
    toolName: input.toolName,
    input: input.encodedArguments,
    errorText: formatInvalidOpenAIToolInputError(
      input.toolName,
      input.decodeError!,
    ),
    providerExecuted: providerExecuted,
    isDynamic: isDynamic,
    title: input.title,
    providerMetadata: metadata(),
  );
}
