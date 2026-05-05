import 'dart:async';

final class ProviderCancelledException implements Exception {
  final Object? reason;

  const ProviderCancelledException([this.reason]);

  String get message => 'Provider invocation cancelled';

  @override
  String toString() {
    final buffer = StringBuffer('ProviderCancelledException(');
    buffer.write('message: $message');
    if (reason != null) {
      buffer.write(', reason: $reason');
    }
    buffer.write(')');
    return buffer.toString();
  }
}

final class ProviderCancellation {
  final Completer<Object?> _completer = Completer<Object?>();

  static bool isCancel(Object error) {
    return error is ProviderCancelledException;
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
      throw ProviderCancelledException(_resolvedReason);
    }
  }
}
