import '../stream/text_stream_event.dart';
import 'chat_ui_message.dart';
import 'chat_ui_tool_input_projection.dart';
import 'chat_ui_tool_part_index.dart';
import 'chat_ui_tool_result_projection.dart';

final class ChatUiToolPartStore {
  final ChatUiToolPartIndex _parts;
  late final ChatUiToolInputProjection _inputs =
      ChatUiToolInputProjection(_parts);
  late final ChatUiToolResultProjection _results =
      ChatUiToolResultProjection(_parts);

  ChatUiToolPartStore(List<ChatUiPart> parts)
      : _parts = ChatUiToolPartIndex(parts);

  void hydrate(ToolUiPart part, int index) {
    _parts.hydrate(part, index);
    _inputs.hydrate(part);
  }

  void clearStreamingInputs() {
    _inputs.clearStreamingInputs();
  }

  void applyInputStart(ToolInputStartEvent event) {
    _inputs.applyInputStart(event);
  }

  void applyInputDelta(ToolInputDeltaEvent event) {
    _inputs.applyInputDelta(event);
  }

  void applyInputEnd(ToolInputEndEvent event) {
    _inputs.applyInputEnd(event);
  }

  void applyInputError(ToolInputErrorEvent event) {
    _inputs.applyInputError(event);
  }

  void applyCall(ToolCallEvent event) {
    _inputs.applyCall(event);
  }

  void applyApprovalRequest(ToolApprovalRequestEvent event) {
    _results.applyApprovalRequest(event);
  }

  void applyResult(ToolResultEvent event) {
    _inputs.discard(event.toolResult.toolCallId);
    _results.applyResult(event);
  }

  void applyOutputDenied(ToolOutputDeniedEvent event) {
    _results.applyOutputDenied(event);
  }
}
