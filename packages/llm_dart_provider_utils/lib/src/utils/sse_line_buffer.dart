/// Simple SSE line buffer helper.
///
/// This utility accumulates incoming string chunks and returns only
/// fully-formed lines (delimited by `\n`). It does **not** apply any
/// SSE semantics such as `data:` or `event:` parsing – callers are
/// responsible for interpreting individual lines.
///
/// Typical usage pattern inside a streaming HTTP client:
///
/// ```dart
/// final buffer = SSELineBuffer();
///
/// await for (final chunk in stream) {
///   final lines = buffer.addChunk(chunkAsString);
///   for (final line in lines) {
///     // line does not include the trailing '\n'
///     // inspect `data:` / `event:` etc. here
///   }
/// }
/// ```
class SSELineBuffer {
  final StringBuffer _buffer = StringBuffer();

  /// Add a new string [chunk] and return all complete lines.
  ///
  /// - Lines are split on `\n`.
  /// - The trailing `\n` characters are not included in the returned
  ///   strings.
  /// - Any partial line at the end of the chunk is kept in the internal
  ///   buffer until more data arrives.
  List<String> addChunk(String chunk) {
    final result = <String>[];

    if (chunk.isEmpty) {
      return result;
    }

    _buffer.write(chunk);
    final content = _buffer.toString();
    final lastNewlineIndex = content.lastIndexOf('\n');

    if (lastNewlineIndex == -1) {
      // No full line yet, keep buffering.
      return result;
    }

    final completeContent = content.substring(0, lastNewlineIndex + 1);
    final remainingContent = content.substring(lastNewlineIndex + 1);

    _buffer
      ..clear()
      ..write(remainingContent);

    final lines = completeContent.split('\n');
    for (final line in lines) {
      // The final split element will be empty when content ends with '\n'.
      if (line.isEmpty) continue;
      result.add(line);
    }

    return result;
  }

  /// Clear the internal buffer.
  void clear() {
    _buffer.clear();
  }
}
