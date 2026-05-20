import 'dart:convert';

import 'json_object_response_decoder.dart';
import 'sse_decoder.dart';

final class SseJsonChunkParser {
  final SseDecoder sseDecoder;

  const SseJsonChunkParser({
    this.sseDecoder = const DefaultSseDecoder(),
  });

  Stream<Map<String, Object?>> parse(
    Stream<List<int>> byteStream, {
    String sourceName = 'SSE stream chunk',
    bool Function(SseFrame frame)? shouldSkipFrame,
  }) async* {
    final frames = sseDecoder.decode(utf8.decoder.bind(byteStream));

    await for (final frame in frames) {
      if ((shouldSkipFrame ?? _defaultShouldSkipFrame)(frame)) {
        continue;
      }

      yield JsonObjectResponseDecoder.decode(
        frame.data,
        sourceName: sourceName,
      );
    }
  }

  static bool _defaultShouldSkipFrame(SseFrame frame) {
    return frame.data.isEmpty || frame.data == '[DONE]';
  }
}
