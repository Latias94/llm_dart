import 'dart:async';

import 'package:llm_dart_ai/llm_dart_ai.dart';
import 'package:llm_dart_chat/llm_dart_chat.dart';
import 'package:test/test.dart';

void main() {
  group('ChatPersistenceAdapter', () {
    test('saves and loads session snapshots through the codec', () async {
      final store = _MemoryPersistenceStore();
      final adapter = ChatPersistenceAdapter(store: store);
      final snapshot = ChatSessionSnapshot(
        chatId: 'chat-1',
        prompt: [
          UserPromptMessage.text('Hello'),
        ],
        messages: [
          ChatUiMessage(
            id: 'user-1',
            role: ChatUiRole.user,
            parts: const [
              TextUiPart(text: 'Hello'),
            ],
          ),
        ],
        status: ChatStatus.ready,
      );
      final session = _FakeChatSession(snapshot);

      await adapter.saveSession(session);

      final stored = store.snapshots['chat-1'] as Map<String, Object?>;
      expect(stored['kind'], ChatSessionSnapshotJsonCodec.envelopeKind);

      final restored = await adapter.loadSnapshot('chat-1');
      expect(restored, isNotNull);
      expect(restored!.chatId, 'chat-1');
      expect(restored.prompt.single, isA<UserPromptMessage>());
      expect(restored.messages.single.role, ChatUiRole.user);
    });

    test('restores typed sessions from persisted snapshots', () async {
      final store = _MemoryPersistenceStore();
      final adapter = ChatPersistenceAdapter(store: store);
      final snapshot = ChatSessionSnapshot(
        chatId: 'chat-2',
        prompt: const [],
        messages: const [],
        status: ChatStatus.awaitingTool,
      );
      final session = _FakeChatSession(snapshot);

      await adapter.saveSession(session);

      final restoredSession = await adapter.restoreSession<_FakeChatSession>(
        'chat-2',
        createSession: _FakeChatSession.new,
      );
      expect(restoredSession, isNotNull);
      expect(restoredSession!.state.status, ChatStatus.awaitingTool);
    });

    test('deletes persisted snapshots', () async {
      final store = _MemoryPersistenceStore();
      final adapter = ChatPersistenceAdapter(store: store);
      store.snapshots['chat-3'] = {
        'schemaVersion': llmDartJsonSchemaVersion,
        'kind': ChatSessionSnapshotJsonCodec.envelopeKind,
        'data': {
          'chatId': 'chat-3',
          'prompt': const [],
          'messages': const [],
          'status': ChatStatus.ready.name,
          'error': null,
        },
      };

      await adapter.deleteSnapshot('chat-3');

      expect(store.snapshots.containsKey('chat-3'), isFalse);
      expect(await adapter.loadSnapshot('chat-3'), isNull);
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
