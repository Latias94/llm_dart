import 'dart:async';

final class TransportCancelledException implements Exception {
  final Object? reason;

  const TransportCancelledException([this.reason]);

  String get message => 'Transport request cancelled';

  @override
  String toString() {
    final buffer = StringBuffer('TransportCancelledException(');
    buffer.write('message: $message');
    if (reason != null) {
      buffer.write(', reason: $reason');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

final class TransportCancellation {
  final Completer<Object?> _completer = Completer<Object?>();

  static bool isCancel(Object error) {
    return error is TransportCancelledException;
  }

  bool get isCancelled => _completer.isCompleted;

  Future<Object?> get whenCancelled => _completer.future;

  Object? get reason => isCancelled ? _resolvedReason : null;

  Object? _resolvedReason;

  void cancel([Object? reason]) {
    if (_completer.isCompleted) {
      return;
    }

    _resolvedReason = reason;
    _completer.complete(reason);
  }

  void throwIfCancelled() {
    if (isCancelled) {
      throw TransportCancelledException(_resolvedReason);
    }
  }
}
