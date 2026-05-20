import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_chat_completions_stream_state.dart';
import 'openai_chat_completions_stream_util.dart';
import '../tools/openai_stream_tool_projection.dart';

Iterable<LanguageModelStreamEvent> decodeOpenAIChatCompletionsToolCallDeltas(
  Map<String, Object?> delta,
  OpenAIChatCompletionsStreamState state,
  OpenAIChatCompletionsStreamMetadataAdapter metadata,
) sync* {
  for (final rawToolCall in openAIChatCompletionsAsList(delta['tool_calls'])) {
    final toolCall = openAIChatCompletionsAsMap(rawToolCall);
    if (toolCall == null) {
      continue;
    }

    final rawIndex = openAIChatCompletionsAsInt(toolCall['index']);
    final index = rawIndex ?? state.toolCalls.length;
    final function = openAIChatCompletionsAsMap(toolCall['function']) ??
        const <String, Object?>{};
    final deltaResult = consumeOpenAIToolCallDelta(
      state: state,
      index: rawIndex,
      fallbackIndex: index,
      fallbackToolCallId: 'tool_$index',
      toolCallId: openAIChatCompletionsAsString(toolCall['id']),
      toolName: openAIChatCompletionsAsString(function['name']),
      argumentsDelta: openAIChatCompletionsAsString(function['arguments']),
    );
    final toolState = deltaResult.toolState;
    if (toolState.toolCallId == null || toolState.toolName == null) {
      continue;
    }

    final startEvent = maybeCreateOpenAIToolInputStartEvent(
      toolState: toolState,
      fallbackToolCallId: 'tool_$index',
      metadata: () => metadata.tool(index),
    );
    if (startEvent != null) {
      yield startEvent;
    }

    final deltaEvent = maybeCreateOpenAIToolInputDeltaEvent(
      toolState: toolState,
      fallbackToolCallId: 'tool_$index',
      delta: deltaResult.argumentsDelta,
      metadata: () => metadata.tool(index),
    );
    if (deltaEvent != null) {
      yield deltaEvent;
    }
  }
}

Iterable<LanguageModelStreamEvent> finalizeOpenAIChatCompletionsToolCalls(
  OpenAIChatCompletionsStreamState state,
  OpenAIChatCompletionsStreamMetadataAdapter metadata,
) sync* {
  for (final entry in state.toolCalls.sortedEntries()) {
    final toolState = entry.value;
    final fallbackToolCallId = 'tool_${entry.key}';
    final startEvent = maybeCreateOpenAIToolInputStartEvent(
      toolState: toolState,
      fallbackToolCallId: fallbackToolCallId,
      metadata: () => metadata.tool(entry.key),
    );
    if (startEvent != null) {
      yield startEvent;
    }

    final resolvedInput = resolveOpenAIStreamToolInput(
      toolState: toolState,
      fallbackToolCallId: fallbackToolCallId,
    );
    if (resolvedInput.decodeError != null) {
      yield createOpenAIToolInputErrorEvent(
        input: resolvedInput,
        metadata: () => metadata.tool(entry.key),
      );
      continue;
    }

    final endEvent = maybeCreateOpenAIToolInputEndEvent(
      toolState: toolState,
      fallbackToolCallId: fallbackToolCallId,
      metadata: () => metadata.tool(entry.key),
    );
    if (endEvent != null) {
      yield endEvent;
    }
    yield ToolCallEvent(
      toolCall: ToolCallContent(
        toolCallId: resolvedInput.toolCallId,
        toolName: resolvedInput.toolName,
        input: resolvedInput.decodedInput,
      ),
      providerMetadata: metadata.tool(entry.key),
    );
  }
  state.toolCalls.clear();
}
