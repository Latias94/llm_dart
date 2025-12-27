import 'dart:convert';

import 'sse_line_buffer.dart';

/// A small parser for newline-delimited JSON (JSONL) streams.
///
/// Many local/self-hosted providers (e.g. Ollama) stream one JSON object per
/// line. Network chunking can split a single JSON line across chunks, so we
/// buffer until a full `\n`-terminated line is available.
class JsonlChunkParser {
  final SseLineBuffer _lineBuffer;

  JsonlChunkParser({SseLineBuffer? lineBuffer})
      : _lineBuffer = lineBuffer ?? SseLineBuffer();

  void reset() => _lineBuffer.clear();

  /// Parses the given [chunk] and returns decoded JSON objects found in complete lines.
  ///
  /// Non-JSON lines or malformed JSON lines are ignored.
  List<Map<String, dynamic>> parseObjects(String chunk) {
    final lines = _lineBuffer.writeAndTakeCompleteLines(chunk);
    if (lines.isEmpty) return const [];

    final results = <Map<String, dynamic>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          results.add(decoded);
        } else if (decoded is Map) {
          results.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // Ignore malformed lines.
      }
    }
    return results;
  }
}
