import 'dart:async';
import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'http_chat_transport_chunk.dart';
import 'http_chat_transport_chunk_json_codec.dart';

final class HttpChatTransportSseEncoder {
  final HttpChatTransportChunkJsonCodec chunkCodec;
  final JsonEncoder jsonEncoder;

  const HttpChatTransportSseEncoder({
    this.chunkCodec = const HttpChatTransportChunkJsonCodec(),
    this.jsonEncoder = const JsonEncoder(),
  });

  SseJsonFrameEncoder get _frameEncoder {
    return SseJsonFrameEncoder(jsonEncoder: jsonEncoder);
  }

  String encodeJsonFrame(
    Map<String, Object?> payload, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    return _frameEncoder.encodeFrame(
      payload,
      event: event,
      id: id,
      retryMilliseconds: retryMilliseconds,
    );
  }

  List<int> encodeJsonFrameBytes(
    Map<String, Object?> payload, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    return _frameEncoder.encodeFrameBytes(
      payload,
      event: event,
      id: id,
      retryMilliseconds: retryMilliseconds,
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

  String encodeDoneFrame() => _frameEncoder.encodeDoneFrame();

  Stream<List<int>> encodeChunkStream(
    Stream<HttpChatTransportChunk> chunks, {
    bool includeDoneFrame = false,
  }) async* {
    await for (final chunk in chunks) {
      yield encodeChunkFrameBytes(chunk);
    }

    if (includeDoneFrame) {
      yield _frameEncoder.encodeDoneFrameBytes();
    }
  }
}
