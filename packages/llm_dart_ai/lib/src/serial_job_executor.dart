import 'dart:async';

/// Executes async jobs sequentially in submission order.
///
/// Mirrors Vercel AI SDK's `SerialJobExecutor`.
class SerialJobExecutor {
  final List<Future<void> Function()> _queue = <Future<void> Function()>[];
  var _isProcessing = false;

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty) {
        final job = _queue.removeAt(0);
        await job();
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> run(FutureOr<void> Function() job) {
    final completer = Completer<void>();

    _queue.add(() async {
      try {
        await Future<void>.value(job());
        completer.complete();
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });

    // Start processing immediately (best-effort). This reduces race windows
    // where callers try to stop/cancel right after submitting a job.
    unawaited(_processQueue());
    return completer.future;
  }
}
