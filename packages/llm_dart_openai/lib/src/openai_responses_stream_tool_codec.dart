import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_responses_stream_state.dart';
import 'openai_responses_stream_util.dart';
import 'openai_responses_support.dart';
import 'openai_stream_tool_projection.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesFunctionCallItemAdded(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final fallbackToolCallId = openAIResponsesAsString(item['call_id']) ??
      openAIResponsesAsString(chunk['item_id']) ??
      'tool';
  final toolState = resolveOpenAIStreamToolCallState(
    state: state,
    index: outputIndex,
    fallbackToolCallId: fallbackToolCallId,
    toolCallId: openAIResponsesAsString(item['call_id']),
    toolName: openAIResponsesAsString(item['name']),
    title: openAIResponsesAsString(item['title']),
    createEphemeralWhenIndexMissing: true,
  );
  final resolvedToolCallId = toolState.resolveToolCallId(fallbackToolCallId);
  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    title: openAIResponsesAsString(item['title']),
    metadata: () => metadata.item(item),
  );
  if (startEvent != null) {
    yield startEvent;
  }
}

Iterable<LanguageModelStreamEvent>
    decodeOpenAIResponsesFunctionCallArgumentsDelta(
  Map<String, Object?> chunk,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  final fallbackToolCallId =
      openAIResponsesAsString(chunk['item_id']) ?? 'tool';
  final deltaResult = consumeOpenAIToolCallDelta(
    state: state,
    index: outputIndex,
    fallbackToolCallId: fallbackToolCallId,
    argumentsDelta: openAIResponsesAsString(chunk['delta']),
    createEphemeralWhenIndexMissing: true,
  );
  final toolState = deltaResult.toolState;
  final resolvedToolCallId = toolState.resolveToolCallId(fallbackToolCallId);
  ProviderMetadata? itemMetadata() => metadata.item();

  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    metadata: itemMetadata,
  );
  if (startEvent != null) {
    yield startEvent;
  }

  final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    delta: deltaResult.argumentsDelta,
    metadata: itemMetadata,
  );
  if (deltaEvent != null) {
    yield deltaEvent;
  }
}

Iterable<LanguageModelStreamEvent> decodeOpenAIResponsesFunctionCallItemDone(
  Map<String, Object?> chunk,
  Map<String, Object?> item,
  OpenAIResponsesStreamState state,
  OpenAIResponsesStreamMetadataAdapter metadata,
) sync* {
  final outputIndex = openAIResponsesAsInt(chunk['output_index']);
  var toolState =
      outputIndex == null ? null : state.toolCalls.remove(outputIndex);
  final fallbackToolCallId = openAIResponsesAsString(item['call_id']) ??
      openAIResponsesAsString(chunk['item_id']) ??
      'tool';

  if (toolState != null) {
    toolState.update(
      toolCallId: openAIResponsesAsString(item['call_id']),
      toolName: openAIResponsesAsString(item['name']),
      title: openAIResponsesAsString(item['title']),
    );
    state.hasToolCalls = true;
  } else {
    toolState = resolveOpenAIStreamToolCallState(
      state: state,
      index: null,
      fallbackToolCallId: fallbackToolCallId,
      toolCallId: openAIResponsesAsString(item['call_id']),
      toolName: openAIResponsesAsString(item['name']),
      title: openAIResponsesAsString(item['title']),
      createEphemeralWhenIndexMissing: true,
    );
  }

  final resolvedToolCallId = toolState.resolveToolCallId(fallbackToolCallId);
  final resolvedToolName = toolState.resolveToolName();
  final providerMetadata = metadata.item(item);

  final startEvent = maybeCreateOpenAIToolInputStartEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    title: openAIResponsesAsString(item['title']),
    metadata: () => providerMetadata,
  );
  if (startEvent != null) {
    yield startEvent;
  }

  final encodedArguments = resolveOpenAIResponsesFunctionCallArguments(
    item,
    fallbackArguments: toolState.arguments.toString(),
  );
  final resolvedInput = resolveOpenAIStreamToolInput(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    fallbackToolName: resolvedToolName,
    encodedArguments: encodedArguments,
  );
  if (resolvedInput.decodeError != null) {
    yield createOpenAIToolInputErrorEvent(
      input: resolvedInput,
      metadata: () => providerMetadata,
    );
    return;
  }

  final endEvent = maybeCreateOpenAIToolInputEndEvent(
    toolState: toolState,
    fallbackToolCallId: resolvedToolCallId,
    metadata: () => providerMetadata,
  );
  if (endEvent != null) {
    yield endEvent;
  }

  final toolCallPart = decodeOpenAIResponsesFunctionCallOutput(
    item,
    fallbackToolCallId: resolvedToolCallId,
    fallbackArguments: toolState.arguments.toString(),
    fallbackToolName: resolvedToolName,
    decodedInput: resolvedInput.decodedInput,
  );
  if (toolCallPart != null) {
    yield ToolCallEvent(
      toolCall: toolCallPart.toolCall,
      providerMetadata: toolCallPart.providerMetadata,
    );
  }
}
