import '../stream/text_stream_event.dart';
import 'tool_input_stream_state.dart';

typedef MissingToolInputErrorFactory = Object Function(String toolCallId);

final class ToolInputStreamStore {
  final MissingToolInputErrorFactory createMissingInputError;
  final Map<String, StreamingToolInputState> _partialInputs = {};

  ToolInputStreamStore({
    required this.createMissingInputError,
  });

  StreamingToolInputState? get(String toolCallId) {
    return _partialInputs[toolCallId];
  }

  void hydrate({
    required String toolCallId,
    required String toolName,
    required bool providerExecuted,
    required bool isDynamic,
    required String? title,
    required Object? input,
    String? inputText,
  }) {
    _partialInputs[toolCallId] = StreamingToolInputState(
      toolName: toolName,
      providerExecuted: providerExecuted,
      isDynamic: isDynamic,
      title: title,
      initialText: inputText ?? stringifyStreamingToolValue(input) ?? '',
    );
  }

  StreamingToolInputState start(ToolInputStartEvent event) {
    final partial = StreamingToolInputState(
      toolName: event.toolName,
      providerExecuted: event.providerExecuted,
      isDynamic: event.isDynamic,
      title: event.title,
      providerMetadata: event.providerMetadata,
    );
    _partialInputs[event.toolCallId] = partial;
    return partial;
  }

  StreamingToolInputState appendDelta(ToolInputDeltaEvent event) {
    final partial = require(event.toolCallId);
    partial.append(event.delta);
    partial.mergeProviderMetadata(event.providerMetadata);
    return partial;
  }

  StreamingToolInputState end(ToolInputEndEvent event) {
    final partial = require(event.toolCallId);
    _partialInputs.remove(event.toolCallId);
    return partial;
  }

  StreamingToolInputState? fail(ToolInputErrorEvent event) {
    return _partialInputs.remove(event.toolCallId);
  }

  void remove(String toolCallId) {
    _partialInputs.remove(toolCallId);
  }

  void clear() {
    _partialInputs.clear();
  }

  StreamingToolInputState require(String toolCallId) {
    final value = _partialInputs[toolCallId];
    if (value != null) {
      return value;
    }

    throw createMissingInputError(toolCallId);
  }
}

StateError missingToolInputStateError(String toolCallId) {
  return StateError(
    'Received tool-input update for missing tool call with ID "$toolCallId". '
    'Ensure a "tool-input-start" event is applied before later tool-input events.',
  );
}
