import '../common/openai_streaming_support.dart';

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
