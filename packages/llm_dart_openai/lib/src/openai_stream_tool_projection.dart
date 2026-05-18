import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_streaming_support.dart';

final class OpenAIConsumedToolCallDelta {
  final int? index;
  final OpenAIStreamToolCallState toolState;
  final String? argumentsDelta;

  const OpenAIConsumedToolCallDelta({
    required this.index,
    required this.toolState,
    required this.argumentsDelta,
  });
}

OpenAIStreamToolCallState resolveOpenAIStreamToolCallState({
  required OpenAIStreamState state,
  required int? index,
  required String fallbackToolCallId,
  String fallbackToolName = 'function',
  String? toolCallId,
  String? toolName,
  String? title,
  bool createEphemeralWhenIndexMissing = false,
}) {
  final resolvedToolCallId =
      firstOpenAINonEmptyString([toolCallId, fallbackToolCallId]);
  final resolvedToolName =
      firstOpenAINonEmptyString([toolName, fallbackToolName]) ??
          fallbackToolName;

  OpenAIStreamToolCallState? toolState;
  if (index != null) {
    toolState = state.toolCalls[index];
  }

  if (toolState == null) {
    if (index == null && createEphemeralWhenIndexMissing) {
      toolState = OpenAIStreamToolCallState(
        index: -1,
        toolCallId: resolvedToolCallId,
        toolName: resolvedToolName,
        title: title,
      );
    } else {
      final resolvedIndex = index ?? state.toolCalls.length;
      toolState = state.toolCalls.resolve(
        resolvedIndex,
        toolCallId: resolvedToolCallId,
        toolName: resolvedToolName,
        title: title,
      );
    }
  } else {
    toolState.update(
      toolCallId: toolCallId,
      toolName: toolName,
      title: title,
    );
  }

  state.hasToolCalls = true;
  return toolState;
}

OpenAIConsumedToolCallDelta consumeOpenAIToolCallDelta({
  required OpenAIStreamState state,
  required int? index,
  int? fallbackIndex,
  required String fallbackToolCallId,
  String fallbackToolName = 'function',
  String? toolCallId,
  String? toolName,
  String? title,
  String? argumentsDelta,
  bool createEphemeralWhenIndexMissing = false,
}) {
  final resolvedIndex = index ?? fallbackIndex;
  final toolState = resolveOpenAIStreamToolCallState(
    state: state,
    index: resolvedIndex,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: fallbackToolName,
    toolCallId: toolCallId,
    toolName: toolName,
    title: title,
    createEphemeralWhenIndexMissing:
        createEphemeralWhenIndexMissing && resolvedIndex == null,
  );
  toolState.update(argumentsDelta: argumentsDelta);

  return OpenAIConsumedToolCallDelta(
    index: resolvedIndex,
    toolState: toolState,
    argumentsDelta: argumentsDelta,
  );
}

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

final class OpenAIResolvedToolInput {
  final String toolCallId;
  final String toolName;
  final String? title;
  final String encodedArguments;
  final Object? decodedInput;
  final FormatException? decodeError;

  const OpenAIResolvedToolInput({
    required this.toolCallId,
    required this.toolName,
    required this.title,
    required this.encodedArguments,
    required this.decodedInput,
    required this.decodeError,
  });
}

OpenAIResolvedToolInput resolveOpenAIStreamToolInput({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  String fallbackToolName = 'function',
  String fallbackArguments = '{}',
  String? encodedArguments,
}) {
  final resolvedArguments =
      encodedArguments ?? toolState.encodedArguments(fallbackArguments);
  final decodedArguments = tryDecodeOpenAIJsonValue(resolvedArguments);

  return OpenAIResolvedToolInput(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    toolName: toolState.resolveToolName(fallbackToolName),
    title: toolState.title,
    encodedArguments: resolvedArguments,
    decodedInput: decodedArguments.value,
    decodeError: decodedArguments.error,
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

String formatInvalidOpenAIToolInputError(
  String toolName,
  FormatException error,
) {
  final message = error.message.trim();
  if (message.isEmpty) {
    return 'Invalid JSON tool arguments for "$toolName".';
  }

  return 'Invalid JSON tool arguments for "$toolName": $message';
}
