import '../common/tool_input_stream_store.dart';
import '../common/tool_input_stream_state.dart';
import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_error.dart';

final class ChatUiToolInputStreamStore {
  final ToolInputStreamStore _inputs = ToolInputStreamStore(
    createMissingInputError: _missingToolInputError,
  );

  StreamingToolInputState? get(String toolCallId) => _inputs.get(toolCallId);

  void hydrate(ToolUiPart part) {
    if (part.state != ToolUiPartState.inputStreaming) {
      return;
    }

    _inputs.hydrate(
      toolCallId: part.toolCallId,
      toolName: part.toolName,
      providerExecuted: part.providerExecuted,
      isDynamic: part.isDynamic,
      title: part.title,
      input: part.input,
      inputText: part.inputText,
    );
  }

  StreamingToolInputState start(ToolInputStartEvent event) =>
      _inputs.start(event);

  StreamingToolInputState appendDelta(ToolInputDeltaEvent event) =>
      _inputs.appendDelta(event);

  StreamingToolInputState end(ToolInputEndEvent event) => _inputs.end(event);

  StreamingToolInputState? fail(ToolInputErrorEvent event) =>
      _inputs.fail(event);

  void remove(String toolCallId) => _inputs.remove(toolCallId);

  void clear() => _inputs.clear();

  StreamingToolInputState require(String toolCallId) =>
      _inputs.require(toolCallId);
}

Object _missingToolInputError(String toolCallId) {
  return ChatUiStreamError(
    chunkType: 'tool-input-update',
    chunkId: toolCallId,
    message: missingToolInputStateError(toolCallId).message,
  );
}
