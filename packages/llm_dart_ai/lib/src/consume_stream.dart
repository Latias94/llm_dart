import 'dart:async';

/// Consumes a [Stream] until it is fully read.
///
/// Mirrors Vercel AI SDK's `consumeStream(...)` helper.
Future<void> consumeStream<T>({
  required Stream<T> stream,
  void Function(Object error)? onError,
}) async {
  try {
    await stream.drain<void>();
  } catch (e) {
    onError?.call(e);
  }
}
