import '../common/tool_input_stream_state.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_error.dart';

final class ChatUiToolInputStreamStore {
  final Map<String, StreamingToolInputState> _partialInputs = {};

  StreamingToolInputState? get(String toolCallId) {
    return _partialInputs[toolCallId];
  }

  void hydrate(ToolUiPart part) {
    if (part.state != ToolUiPartState.inputStreaming) {
      return;
    }

    _partialInputs[part.toolCallId] = StreamingToolInputState(
      toolName: part.toolName,
      providerExecuted: part.providerExecuted,
      isDynamic: part.isDynamic,
      title: part.title,
      initialText:
          part.inputText ?? stringifyStreamingToolValue(part.input) ?? '',
    );
  }

  StreamingToolInputState start(ToolInputStartEvent event) {
    final partial = StreamingToolInputState(
      toolName: event.toolName,
      providerExecuted: event.providerExecuted,
      isDynamic: event.isDynamic,
      title: event.title,
    );
    _partialInputs[event.toolCallId] = partial;
    return partial;
  }

  StreamingToolInputState appendDelta(ToolInputDeltaEvent event) {
    final partial = require(event.toolCallId);
    partial.append(event.delta);
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

    throw ChatUiStreamError(
      chunkType: 'tool-input-update',
      chunkId: toolCallId,
      message:
          'Received tool-input update for missing tool call with ID "$toolCallId". '
          'Ensure a "tool-input-start" event is applied before later tool-input events.',
    );
  }
}
