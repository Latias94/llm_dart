import 'dart:async';

import 'transport_exception.dart';

final class TransportCancelledException extends TransportException {
  final Object? reason;

  const TransportCancelledException([this.reason])
      : super(
          'Transport request cancelled',
          cause: reason,
        );
}

final class TransportCancellation {
  final Completer<Object?> _completer = Completer<Object?>();

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
