import 'dart:convert';

import 'json_object_response_decoder.dart';
import 'utf8_stream_decoder.dart';

final class NdjsonJsonChunkParser {
  const NdjsonJsonChunkParser();

  Stream<Map<String, Object?>> parse(
    Stream<List<int>> byteStream, {
    String sourceName = 'NDJSON stream chunk',
    bool allowMalformedUtf8 = false,
    bool Function(String line)? shouldSkipLine,
  }) async* {
    final skipLine = shouldSkipLine ?? _defaultShouldSkipLine;

    await for (final line in byteStream
        .decodeUtf8Stream(allowMalformed: allowMalformedUtf8)
        .transform(const LineSplitter())) {
      if (skipLine(line)) {
        continue;
      }

      yield JsonObjectResponseDecoder.decode(
        line.trim(),
        sourceName: sourceName,
      );
    }
  }

  static bool _defaultShouldSkipLine(String line) {
    return line.trim().isEmpty;
  }
}
