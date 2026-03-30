import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

import 'chat_input.dart';
import 'chat_request_options.dart';
import 'chat_session.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';

/// Flutter convenience wrapper above [ChatSession].
///
/// The controller does not own another state machine.
/// It mirrors the underlying session state into a [ValueNotifier].
/// Call [close] when you want to await shutdown explicitly.
/// [dispose] triggers the same shutdown path asynchronously.
final class ChatController extends ValueNotifier<ChatState> {
  final ChatSession session;
  final bool disposeSession;

  late final StreamSubscription<ChatState> _subscription;
  Future<void>? _closeFuture;
  bool _isClosed = false;
  bool _notifierDisposed = false;

  ChatController({
    required this.session,
    this.disposeSession = true,
  }) : super(session.state) {
    _subscription = session.states.listen((state) {
      if (_isClosed) {
        return;
      }

      super.value = state;
    });
  }

  ChatState get state => super.value;

  ChatStatus get status => state.status;

  List<ChatUiMessage> get messages => state.messages;

  ModelError? get error => state.error;

  @override
  set value(ChatState _) {
    throw UnsupportedError(
      'ChatController state is read-only. Use session actions to change it.',
    );
  }

  Stream<ChatState> get states => session.states;

  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) {
    return session.sendMessage(input, options: options);
  }

  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  }) {
    return session.regenerate(
      messageId: messageId,
      options: options,
    );
  }

  Future<void> addToolOutput(ToolOutputUpdate update) {
    return session.addToolOutput(update);
  }

  Future<void> addDataPart<T>(DataUiPart<T> part) {
    return session.addDataPart(part);
  }

  Future<void> respondToolApproval(ToolApprovalResponse response) {
    return session.respondToolApproval(response);
  }

  Future<void> resume() {
    return session.resume();
  }

  Future<void> stop() {
    return session.stop();
  }

  Future<void> clearError() {
    return session.clearError();
  }

  ChatSessionSnapshot exportSnapshot() {
    return session.exportSnapshot();
  }

  Future<void> close() {
    return _closeFuture ??= _closeInternal();
  }

  Future<void> _closeInternal() async {
    _isClosed = true;
    await _subscription.cancel();
    if (disposeSession) {
      await session.dispose();
    }
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
  }

  @override
  void dispose() {
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
    unawaited(close());
  }
}
