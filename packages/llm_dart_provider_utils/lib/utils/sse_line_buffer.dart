/// Minimal SSE line buffer that supports incremental chunk parsing.
///
/// It accumulates chunk fragments and yields complete `\n`-terminated lines,
/// keeping any trailing incomplete fragment buffered for the next chunk.
class SseLineBuffer {
  final StringBuffer _buffer = StringBuffer();

  void clear() => _buffer.clear();

  List<String> writeAndTakeCompleteLines(String chunk) {
    _buffer.write(chunk);

    final bufferContent = _buffer.toString();
    final lastNewlineIndex = bufferContent.lastIndexOf('\n');
    if (lastNewlineIndex == -1) {
      return const [];
    }

    final completeContent = bufferContent.substring(0, lastNewlineIndex + 1);
    final remainingContent = bufferContent.substring(lastNewlineIndex + 1);

    _buffer.clear();
    if (remainingContent.isNotEmpty) {
      _buffer.write(remainingContent);
    }

    // `String.split` returns a trailing empty element when the input ends
    // with the delimiter. Since we only split on complete `\n`-terminated
    // content, that trailing empty element is an artifact and would
    // incorrectly appear as a blank line to higher-level parsers.
    final parts = completeContent.split('\n');
    if (parts.isNotEmpty && parts.last.isEmpty) {
      parts.removeLast();
    }
    return parts;
  }
}
