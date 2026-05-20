import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_code_interpreter_projection.dart';
import '../tools/openai_stream_tool_projection.dart';
import '../common/openai_streaming_support.dart';

Iterable<LanguageModelStreamEvent>
    openAIResponsesEnsureCodeInterpreterInputStarted({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  required String? containerId,
  required ProviderMetadata? Function() metadata,
}) sync* {
  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
    metadata: metadata,
    providerExecuted: true,
  );
  if (startEvent == null) {
    return;
  }

  final prefix = openAIResponsesCodeInterpreterInputPrefix(containerId);
  toolState.update(argumentsDelta: prefix);
  yield startEvent;
  yield ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    delta: prefix,
    providerMetadata: metadata(),
  );
}

Iterable<LanguageModelStreamEvent> openAIResponsesFinishCodeInterpreterInput({
  required OpenAIStreamToolCallState toolState,
  required String fallbackToolCallId,
  required String? containerId,
  required String? codeIfMissing,
  required ProviderMetadata? Function() metadata,
}) sync* {
  if (toolState.endEmitted) {
    return;
  }

  yield* openAIResponsesEnsureCodeInterpreterInputStarted(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    containerId: containerId,
    metadata: metadata,
  );

  final current = toolState.encodedArguments('');
  if (codeIfMissing != null &&
      openAIResponsesCodeInterpreterInputHasOnlyPrefix(current)) {
    final escaped = openAIResponsesEscapeJsonStringContent(codeIfMissing);
    toolState.update(argumentsDelta: escaped);
    yield ToolInputDeltaEvent(
      toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
      delta: escaped,
      providerMetadata: metadata(),
    );
  }

  toolState.update(argumentsDelta: openAIResponsesCodeInterpreterInputSuffix);
  yield ToolInputDeltaEvent(
    toolCallId: toolState.resolveToolCallId(fallbackToolCallId),
    delta: openAIResponsesCodeInterpreterInputSuffix,
    providerMetadata: metadata(),
  );

  final resolvedInput = resolveOpenAIStreamToolInput(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    fallbackToolName: openAIResponsesCodeInterpreterToolName,
  );
  if (resolvedInput.decodeError != null) {
    yield createOpenAIToolInputErrorEvent(
      input: resolvedInput,
      metadata: metadata,
      providerExecuted: true,
    );
    return;
  }

  final endEvent = maybeCreateOpenAIToolInputEndEvent(
    toolState: toolState,
    fallbackToolCallId: fallbackToolCallId,
    metadata: metadata,
  );
  if (endEvent != null) {
    yield endEvent;
  }

  yield ToolCallEvent(
    toolCall: ToolCallContent(
      toolCallId: resolvedInput.toolCallId,
      toolName: openAIResponsesCodeInterpreterToolName,
      input: resolvedInput.decodedInput,
      providerExecuted: true,
    ),
    providerMetadata: metadata(),
  );
}
