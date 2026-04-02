import 'dart:async';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_flutter/llm_dart_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('ChatPersistenceAdapter', () {
    test('saves controllers and restores typed sessions and controllers',
        () async {
      final store = _MemoryPersistenceStore();
      final adapter = ChatPersistenceAdapter(store: store);
      final snapshot = ChatSessionSnapshot(
        chatId: 'chat-1',
        prompt: const [],
        messages: const [],
        status: ChatStatus.awaitingTool,
      );
      final session = _FakeChatSession(snapshot);
      final controller = ChatController(
        session: session,
        disposeSession: false,
      );

      await adapter.saveController(controller);

      final restoredSession = await adapter.restoreSession<_FakeChatSession>(
        'chat-1',
        createSession: _FakeChatSession.new,
      );
      expect(restoredSession, isNotNull);
      expect(restoredSession!.state.status, ChatStatus.awaitingTool);

      final restoredController =
          await adapter.restoreController<ChatController>(
        'chat-1',
        createController: (restoredSnapshot) => ChatController(
          session: _FakeChatSession(restoredSnapshot),
          disposeSession: false,
        ),
      );
      expect(restoredController, isNotNull);
      expect(restoredController!.state.chatId, 'chat-1');

      await controller.close();
      await restoredController.close();
    });
  });
}

final class _MemoryPersistenceStore implements ChatPersistenceStore {
  final Map<String, Object?> snapshots = <String, Object?>{};

  @override
  Future<void> deleteSnapshot(String chatId) async {
    snapshots.remove(chatId);
  }

  @override
  Future<Object?> readSnapshot(String chatId) async {
    return snapshots[chatId];
  }

  @override
  Future<void> writeSnapshot(
    String chatId,
    Object? snapshotEnvelope,
  ) async {
    snapshots[chatId] = snapshotEnvelope;
  }
}

final class _FakeChatSession implements ChatSession {
  final StreamController<ChatState> _statesController =
      StreamController<ChatState>.broadcast(sync: true);
  final StreamController<DataUiPart<Object?>> _transientDataPartsController =
      StreamController<DataUiPart<Object?>>.broadcast(sync: true);

  final ChatState _state;
  final ChatSessionSnapshot _snapshot;
  int disposeCount = 0;

  _FakeChatSession(ChatSessionSnapshot snapshot)
      : _snapshot = snapshot,
        _state = ChatState(
          chatId: snapshot.chatId,
          messages: snapshot.messages,
          status: snapshot.status,
          error: snapshot.error,
        );

  @override
  ChatState get state => _state;

  @override
  Stream<ChatState> get states => _statesController.stream;

  @override
  Stream<DataUiPart<Object?>> get transientDataParts =>
      _transientDataPartsController.stream;

  @override
  Future<void> sendMessage(
    ChatInput input, {
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {}

  @override
  Future<void> regenerate({
    String? messageId,
    ChatRequestOptions options = const ChatRequestOptions(),
  }) async {}

  @override
  Future<void> addToolOutput(ToolOutputUpdate update) async {}

  @override
  Future<void> addDataPart<T>(DataUiPart<T> part) async {}

  @override
  Future<void> respondToolApproval(ToolApprovalResponse response) async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> clearError() async {}

  @override
  ChatSessionSnapshot exportSnapshot() => _snapshot;

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
