import 'dart:async';

/// Creates a [Stream] that emits the provided [chunks] with optional delays.
///
/// Mirrors Vercel AI SDK's `simulateReadableStream(...)`.
///
/// Notes:
/// - `null` means no delay is applied.
/// - `Duration.zero` still yields to the event loop.
Stream<T> simulateStream<T>({
  required List<T> chunks,
  Duration? initialDelay = Duration.zero,
  Duration? chunkDelay = Duration.zero,
}) async* {
  for (var i = 0; i < chunks.length; i++) {
    final delay = i == 0 ? initialDelay : chunkDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    yield chunks[i];
  }
}
