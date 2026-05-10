import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';

void main() {
  group('ChatController', () {
    test('mirrors the underlying session state into ValueNotifier', () async {
      final session = _FakeChatSession(
        ChatState(
          chatId: 'chat-1',
          messages: const [],
        ),
      );
      final controller = ChatController(session: session);

      expect(controller.state.chatId, 'chat-1');
      expect(controller.messages, isEmpty);

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount += 1;
      });

      session.emit(
        ChatState(
          chatId: 'chat-1',
          messages: [
            ChatUiMessage(
              id: 'assistant-1',
              role: ChatUiRole.assistant,
              parts: const [
                TextUiPart(text: 'Hello'),
              ],
            ),
          ],
          status: ChatStatus.streaming,
        ),
      );

      expect(controller.status, ChatStatus.streaming);
      expect(controller.messages.single.parts.single, isA<TextUiPart>());
      expect(notificationCount, 1);

      await controller.close();
    });

    test('delegates actions and disposes the owned session by default',
        () async {
      final session = _FakeChatSession(
        ChatState(
          chatId: 'chat-1',
          messages: const [],
        ),
      );
      final controller = ChatController(session: session);

      await controller.sendMessage(ChatInput.text('Hello'));
      await controller.regenerate();
      await controller.stop();
      await controller.clearError();

      expect(session.sentMessages, ['Hello']);
      expect(session.regenerateCount, 1);
      expect(session.stopCount, 1);
      expect(session.clearErrorCount, 1);

      await controller.close();

      expect(session.disposeCount, 1);
    });

    test('can leave session disposal to the caller', () async {
      final session = _FakeChatSession(
        ChatState(
          chatId: 'chat-1',
          messages: const [],
        ),
      );
      final controller = ChatController(
        session: session,
        disposeSession: false,
      );

      await controller.close();

      expect(session.disposeCount, 0);
      await session.dispose();
      expect(session.disposeCount, 1);
    });

    test('forwards transient data parts from the session', () async {
      final session = _FakeChatSession(
        ChatState(
          chatId: 'chat-1',
          messages: const [],
        ),
      );
      final controller = ChatController(session: session);

      final nextTransientPart = controller.transientDataParts.first;
      session.emitTransientDataPart(
        const DataUiPart<Object?>(
          id: 'heartbeat',
          key: 'tool-status',
          data: {
            'phase': 'running',
          },
        ),
      );

      final part = await nextTransientPart;
      expect(part.id, 'heartbeat');
      expect(part.key, 'tool-status');
      expect((part.data as Map<String, Object?>)['phase'], 'running');

      await controller.close();
    });
  });
}

final class _FakeChatSession implements ChatSession {
  final StreamController<ChatState> _statesController =
      StreamController<ChatState>.broadcast(sync: true);
  final StreamController<DataUiPart<Object?>> _transientDataPartsController =
      StreamController<DataUiPart<Object?>>.broadcast(sync: true);

  ChatState _state;
  final List<String> sentMessages = [];
  int regenerateCount = 0;
  int stopCount = 0;
  int clearErrorCount = 0;
  int disposeCount = 0;

  _FakeChatSession(this._state);

  void emit(ChatState state) {
    _state = state;
    _statesController.add(state);
  }

  @override
  ChatState get state => _state;

  @override
  Stream<ChatState> get states => _statesController.stream;

  @override
  Stream<DataUiPart<Object?>> get transientDataParts =>
      _transientDataPartsController.stream;

  void emitTransientDataPart(DataUiPart<Object?> part) {
    _transientDataPartsController.add(part);
  }

  @override
  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    final message = input.message;
    if (message is UserPromptMessage) {
      sentMessages.add(
        message.parts
            .whereType<TextPromptPart>()
            .map((part) => part.text)
            .join(),
      );
    }
  }

  @override
  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {
    regenerateCount += 1;
  }

  @override
  Future<void> addToolOutput(ToolOutputUpdate update) async {}

  @override
  Future<void> addDataPart<T>(DataUiPart<T> part) async {}

  @override
  Future<void> respondToolApproval(ToolApprovalResponse response) async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> clearError() async {
    clearErrorCount += 1;
  }

  @override
  ChatSessionSnapshot exportSnapshot() {
    return ChatSessionSnapshot(
      chatId: state.chatId,
      prompt: const [],
      messages: state.messages,
      status: state.status,
      error: state.error,
    );
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    if (!_transientDataPartsController.isClosed) {
      await _transientDataPartsController.close();
    }
    if (!_statesController.isClosed) {
      await _statesController.close();
    }
  }
}
