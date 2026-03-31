import 'dart:convert';

import 'sse_decoder.dart';

final class SseJsonChunkParser {
  final SseDecoder sseDecoder;

  const SseJsonChunkParser({
    this.sseDecoder = const DefaultSseDecoder(),
  });

  Stream<Map<String, Object?>> parse(
    Stream<List<int>> byteStream, {
    bool Function(SseFrame frame)? shouldSkipFrame,
  }) async* {
    final frames = sseDecoder.decode(utf8.decoder.bind(byteStream));

    await for (final frame in frames) {
      if ((shouldSkipFrame ?? _defaultShouldSkipFrame)(frame)) {
        continue;
      }

      yield _decodeJsonObjectFrame(frame.data);
    }
  }

  static bool _defaultShouldSkipFrame(SseFrame frame) {
    return frame.data.isEmpty || frame.data == '[DONE]';
  }

  static Map<String, Object?> _decodeJsonObjectFrame(String data) {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }

    throw FormatException(
      'Expected a JSON object SSE payload but received ${decoded.runtimeType}.',
      data,
    );
  }
}
