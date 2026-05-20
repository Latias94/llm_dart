import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_state.dart';

final class DefaultChatSessionStateController {
  final StreamController<ChatState> _statesController;
  final StreamController<DataUiPart<Object?>> _transientDataPartsController;

  ChatState _state;
  bool _isDisposed = false;

  DefaultChatSessionStateController(ChatState initialState)
      : _state = initialState,
        _statesController = StreamController<ChatState>.broadcast(sync: true),
        _transientDataPartsController =
            StreamController<DataUiPart<Object?>>.broadcast(sync: true);

  ChatState get state => _state;

  bool get isDisposed => _isDisposed;

  Stream<ChatState> get states => _statesController.stream;

  Stream<DataUiPart<Object?>> get transientDataParts =>
      _transientDataPartsController.stream;

  void emitState(ChatState state) {
    _state = state;
    if (!_isDisposed && !_statesController.isClosed) {
      _statesController.add(state);
    }
  }

  void emitTransientDataPart(DataUiPart<Object?> part) {
    if (!_isDisposed && !_transientDataPartsController.isClosed) {
      _transientDataPartsController.add(part);
    }
  }

  void ensureUsable() {
    if (_isDisposed) {
      throw StateError('This chat session has already been disposed.');
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    if (!_transientDataPartsController.isClosed) {
      await _transientDataPartsController.close();
    }
    if (!_statesController.isClosed) {
      await _statesController.close();
    }
  }
}
