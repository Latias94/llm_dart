final class SseFrame {
  final String? event;
  final String data;
  final String? id;
  final int? retryMilliseconds;

  const SseFrame({
    this.event,
    required this.data,
    this.id,
    this.retryMilliseconds,
  });
}

abstract interface class SseDecoder {
  Stream<SseFrame> decode(Stream<String> chunks);
}
