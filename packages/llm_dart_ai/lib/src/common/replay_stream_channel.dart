import 'dart:async';

final class ReplayStreamChannel<T> {
  final List<T> _history = <T>[];
  final Set<MultiStreamController<T>> _controllers =
      <MultiStreamController<T>>{};

  Object? _error;
  StackTrace? _stackTrace;
  bool _isClosed = false;

  Stream<T> get stream => Stream<T>.multi(
        (controller) {
          for (final value in _history) {
            controller.add(value);
          }

          if (_error case final error?) {
            controller.addError(error, _stackTrace);
            controller.close();
            return;
          }

          if (_isClosed) {
            controller.close();
            return;
          }

          _controllers.add(controller);
          controller.onCancel = () {
            _controllers.remove(controller);
          };
        },
        isBroadcast: true,
      );

  void add(T value) {
    if (_isClosed || _error != null) {
      return;
    }

    _history.add(value);
    for (final controller in _controllers.toList(growable: false)) {
      controller.add(value);
    }
  }

  void addError(Object error, StackTrace stackTrace) {
    if (_isClosed || _error != null) {
      return;
    }

    _error = error;
    _stackTrace = stackTrace;
    _isClosed = true;

    for (final controller in _controllers.toList(growable: false)) {
      controller.addError(error, stackTrace);
      controller.close();
    }
    _controllers.clear();
  }

  void close() {
    if (_isClosed || _error != null) {
      return;
    }

    _isClosed = true;

    for (final controller in _controllers.toList(growable: false)) {
      controller.close();
    }
    _controllers.clear();
  }
}
