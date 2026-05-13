import 'dart:async';

import '../common/replay_stream_channel.dart';

final class StreamResultHandle<TEvent, TResult> {
  final Stream<TEvent> eventStream;
  final Future<TResult> result;

  const StreamResultHandle({
    required this.eventStream,
    required this.result,
  });

  Future<TValue> select<TValue>(
    TValue Function(TResult result) selector,
  ) {
    return result.then(selector);
  }
}

final class StreamResultController<TEvent, TResult> {
  final ReplayStreamChannel<TEvent> _eventChannel =
      ReplayStreamChannel<TEvent>();
  final Completer<TResult> _resultCompleter = Completer<TResult>();
  final List<_ManagedSideChannel> _sideChannels = <_ManagedSideChannel>[];

  late final StreamResultHandle<TEvent, TResult> handle =
      StreamResultHandle<TEvent, TResult>(
    eventStream: _eventChannel.stream,
    result: _resultCompleter.future,
  );

  Stream<TEvent> get eventStream => handle.eventStream;

  Future<TResult> get result => handle.result;

  bool get isResultCompleted => _resultCompleter.isCompleted;

  Future<TValue> select<TValue>(
    TValue Function(TResult result) selector,
  ) {
    return handle.select(selector);
  }

  StreamSideChannel<T> createSideChannel<T>() {
    final sideChannel = StreamSideChannel<T>._();
    _sideChannels.add(sideChannel);
    return sideChannel;
  }

  void addEvent(TEvent event) {
    _eventChannel.add(event);
  }

  void completeResult(TResult result) {
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.complete(result);
    }
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (!_resultCompleter.isCompleted) {
      _resultCompleter.completeError(error, stackTrace);
    }
  }

  void fail(Object error, StackTrace stackTrace) {
    completeError(error, stackTrace);
    _eventChannel.addError(error, stackTrace);
    for (final sideChannel in _sideChannels) {
      sideChannel.addError(error, stackTrace);
    }
  }

  void close() {
    _eventChannel.close();
    for (final sideChannel in _sideChannels) {
      sideChannel.close();
    }
  }
}

abstract interface class _ManagedSideChannel {
  void addError(Object error, StackTrace stackTrace);

  void close();
}

final class StreamSideChannel<T> implements _ManagedSideChannel {
  final ReplayStreamChannel<T> _channel = ReplayStreamChannel<T>();

  StreamSideChannel._();

  Stream<T> get stream => _channel.stream;

  void add(T value) {
    _channel.add(value);
  }

  @override
  void addError(Object error, StackTrace stackTrace) {
    _channel.addError(error, stackTrace);
  }

  @override
  void close() {
    _channel.close();
  }
}
