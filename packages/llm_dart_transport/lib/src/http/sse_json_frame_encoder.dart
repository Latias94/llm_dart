import 'dart:async';
import 'dart:convert';

final class SseJsonFrameEncoder {
  final JsonEncoder jsonEncoder;

  const SseJsonFrameEncoder({
    this.jsonEncoder = const JsonEncoder(),
  });

  String encodeFrame(
    Object? payload, {
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

  List<int> encodeFrameBytes(
    Object? payload, {
    String? event,
    String? id,
    int? retryMilliseconds,
  }) {
    return utf8.encode(
      encodeFrame(
        payload,
        event: event,
        id: id,
        retryMilliseconds: retryMilliseconds,
      ),
    );
  }

  String encodeDoneFrame() => 'data: [DONE]\n\n';

  List<int> encodeDoneFrameBytes() => utf8.encode(encodeDoneFrame());

  Stream<List<int>> encodeFrameStream(
    Stream<Object?> payloads, {
    bool includeDoneFrame = false,
  }) async* {
    await for (final payload in payloads) {
      yield encodeFrameBytes(payload);
    }

    if (includeDoneFrame) {
      yield encodeDoneFrameBytes();
    }
  }
}
