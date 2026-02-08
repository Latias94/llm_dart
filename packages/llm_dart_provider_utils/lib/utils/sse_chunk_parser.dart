import 'sse_line_buffer.dart';

/// A parsed SSE event payload, optionally associated with an `event:` name.
class SseDataLine {
  final String data;
  final String? event;

  const SseDataLine(this.data, {this.event});
}

/// A small, tolerant SSE parser for providers that stream text/event-stream.
///
/// It supports:
/// - `event:` lines (stored until the end of the current event)
/// - `data:` lines (concatenated with `\n` until the end of the current event)
/// - incremental chunk parsing via an internal line buffer
///
/// Note: This parser intentionally implements only the subset of SSE semantics
/// that LLM providers commonly use. In particular, it concatenates multi-line
/// `data:` fields per the SSE spec so that JSON payloads split across multiple
/// `data:` lines remain parseable.
class SseChunkParser {
  final SseLineBuffer _lineBuffer;
  String? _currentEvent;
  final List<String> _currentDataLines = <String>[];

  SseChunkParser({SseLineBuffer? lineBuffer})
      : _lineBuffer = lineBuffer ?? SseLineBuffer();

  void reset() {
    _lineBuffer.clear();
    _currentEvent = null;
    _currentDataLines.clear();
  }

  List<SseDataLine> parse(String chunk) {
    final lines = _lineBuffer.writeAndTakeCompleteLines(chunk);
    if (lines.isEmpty) return const [];

    final results = <SseDataLine>[];

    for (final line in lines) {
      final trimmed = line.trimRight();

      if (trimmed.isEmpty) {
        // Blank line terminates an SSE event.
        if (_currentDataLines.isNotEmpty) {
          results.add(
            SseDataLine(
              _currentDataLines.join('\n'),
              event: _currentEvent,
            ),
          );
        }
        _currentEvent = null;
        _currentDataLines.clear();
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
        var data = trimmed.substring('data:'.length);
        // Per SSE spec, a single leading space after ":" is ignored.
        if (data.startsWith(' ')) {
          data = data.substring(1);
        }
        _currentDataLines.add(data);
      }
    }

    return results;
  }
}
