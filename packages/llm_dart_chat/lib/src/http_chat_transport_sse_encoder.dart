import 'dart:async';
import 'dart:convert';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_chunk_json_codec.dart';

final class HttpChatTransportSseEncoder {
  final HttpChatTransportChunkJsonCodec chunkCodec;
  final JsonEncoder jsonEncoder;

  const HttpChatTransportSseEncoder({
    this.chunkCodec = const HttpChatTransportChunkJsonCodec(),
    this.jsonEncoder = const JsonEncoder(),
  });

  String encodeJsonFrame(
    Map<String, Object?> payload, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    final buffer = StringBuffer();
    if (event != null) {
      buffer.writeln('event: $event');
    }
    if (id != null) {
      buffer.writeln('id: $id');
    }
    if (retryMilliseconds != null) {
      buffer.writeln('retry: $retryMilliseconds');
    }

    final data = jsonEncoder.convert(payload);
    for (final line in const LineSplitter().convert(data)) {
      buffer.writeln('data: $line');
    }
    buffer.writeln();
    return buffer.toString();
  }

  List<int> encodeJsonFrameBytes(
    Map<String, Object?> payload, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    return utf8.encode(
      encodeJsonFrame(
        payload,
        event: event,
        id: id,
        retryMilliseconds: retryMilliseconds,
      ),
    );
  }

  String encodeChunkFrame(
    HttpChatTransportChunk chunk, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    return encodeJsonFrame(
      chunkCodec.encodeChunk(chunk),
      event: event,
      id: id,
      retryMilliseconds: retryMilliseconds,
    );
  }

  List<int> encodeChunkFrameBytes(
    HttpChatTransportChunk chunk, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    return utf8.encode(
      encodeChunkFrame(
        chunk,
        event: event,
        id: id,
        retryMilliseconds: retryMilliseconds,
      ),
    );
  }

  String encodeDoneFrame() => 'data: [DONE]\n\n';

  Stream<List<int>> encodeChunkStream(
    Stream<HttpChatTransportChunk> chunks, {
    bool includeDoneFrame = false,
  }) async* {
    await for (final chunk in chunks) {
      yield encodeChunkFrameBytes(chunk);
    }

    if (includeDoneFrame) {
      yield utf8.encode(encodeDoneFrame());
    }
  }
}
