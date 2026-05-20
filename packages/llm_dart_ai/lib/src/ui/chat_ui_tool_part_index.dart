import 'chat_ui_message.dart';
import 'chat_ui_stream_error.dart';

final class ChatUiToolPartIndex {
  final List<ChatUiPart> _parts;
  final Map<String, int> _partIndexes = {};

  ChatUiToolPartIndex(this._parts);

  void hydrate(ToolUiPart part, int index) {
    _partIndexes[part.toolCallId] = index;
  }

  ToolUiPart? get(String toolCallId) {
    final index = _partIndexes[toolCallId];
    if (index == null) {
      return null;
    }

    return _parts[index] as ToolUiPart;
  }

  ToolUiPart require(
    String toolCallId, {
    required String chunkType,
    required String message,
  }) {
    final part = get(toolCallId);
    if (part != null) {
      return part;
    }

    throw ChatUiStreamError(
      chunkType: chunkType,
      chunkId: toolCallId,
      message: message,
    );
  }

  void upsert(ToolUiPart part) {
    final index = _partIndexes[part.toolCallId];
    if (index == null) {
      _partIndexes[part.toolCallId] = _append(part);
      return;
    }

    _parts[index] = part;
  }

  int _append(ToolUiPart part) {
    _parts.add(part);
    return _parts.length - 1;
  }
}
