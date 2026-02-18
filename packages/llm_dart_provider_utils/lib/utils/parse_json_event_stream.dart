import 'parse_json.dart';
import 'sse_chunk_parser.dart';
import 'utf8_stream_decoder.dart';

/// Parses a `text/event-stream` JSON event stream into a stream of parsed objects.
///
/// This is a small Dart counterpart to the upstream AI SDK `parseJsonEventStream(...)`.
///
/// Notes:
/// - Ignores `[DONE]` events (OpenAI-style).
/// - Does not throw on parse failures; emits `ParseResult.failure(...)`.
Stream<ParseResult<T>> parseJsonEventStream<T>({
  required Stream<List<int>> stream,
  required T Function(Object? json) decode,
}) async* {
  final decoder = Utf8StreamDecoder();
  final parser = SseChunkParser();

  await for (final bytes in stream) {
    final text = decoder.decode(bytes);
    if (text.isEmpty) continue;

    final events = parser.parse(text);
    for (final event in events) {
      final data = event.data;
      if (data == '[DONE]') continue;
      yield safeParseJson<T>(text: data, decode: decode);
    }
  }

  final remaining = decoder.flush();
  if (remaining.isNotEmpty) {
    final events = parser.parse(remaining);
    for (final event in events) {
      final data = event.data;
      if (data == '[DONE]') continue;
      yield safeParseJson<T>(text: data, decode: decode);
    }
  }
}
