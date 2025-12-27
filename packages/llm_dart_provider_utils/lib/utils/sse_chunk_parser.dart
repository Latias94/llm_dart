import 'sse_line_buffer.dart';

/// A parsed SSE `data:` line, optionally associated with the most recent `event:`.
class SseDataLine {
  final String data;
  final String? event;

  const SseDataLine(this.data, {this.event});
}

/// A small, tolerant SSE parser for providers that stream line-delimited SSE.
///
/// It supports:
/// - `event:` lines (stored until the next blank line)
/// - `data:` lines (emitted as [SseDataLine])
/// - incremental chunk parsing via an internal line buffer
///
/// Note: This parser is intentionally minimal and does not implement the full
/// SSE spec (e.g. multi-line `data:` concatenation semantics). It's designed to
/// match common LLM provider streaming patterns.
class SseChunkParser {
  final SseLineBuffer _lineBuffer;
  String? _currentEvent;

  SseChunkParser({SseLineBuffer? lineBuffer})
      : _lineBuffer = lineBuffer ?? SseLineBuffer();

  void reset() {
    _lineBuffer.clear();
    _currentEvent = null;
  }

  List<SseDataLine> parse(String chunk) {
    final lines = _lineBuffer.writeAndTakeCompleteLines(chunk);
    if (lines.isEmpty) return const [];

    final results = <SseDataLine>[];

    for (final line in lines) {
      final trimmed = line.trimRight();

      if (trimmed.isEmpty) {
        // Blank line terminates an SSE event.
        _currentEvent = null;
        continue;
      }

      // SSE comments (":"-prefixed) are ignored.
      if (trimmed.startsWith(':')) {
        continue;
      }

      if (trimmed.startsWith('event:')) {
        _currentEvent = trimmed.substring('event:'.length).trim();
        continue;
      }

      if (trimmed.startsWith('data:')) {
        final data = trimmed.substring('data:'.length).trim();
        results.add(SseDataLine(data, event: _currentEvent));
      }
    }

    return results;
  }
}
