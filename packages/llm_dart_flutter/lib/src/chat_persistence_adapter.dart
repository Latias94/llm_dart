import 'chat_controller.dart';
import 'chat_session.dart';
import 'chat_session_snapshot.dart';
import 'chat_session_snapshot_json_codec.dart';

abstract interface class ChatPersistenceStore {
  Future<Object?> readSnapshot(String chatId);

  Future<void> writeSnapshot(
    String chatId,
    Object? snapshotEnvelope,
  );

  Future<void> deleteSnapshot(String chatId);
}

/// Thin persistence helper above session snapshots.
///
/// Storage remains application-owned.
/// This adapter only handles snapshot encoding, decoding, and restoration.
final class ChatPersistenceAdapter {
  final ChatPersistenceStore store;
  final ChatSessionSnapshotJsonCodec codec;

  const ChatPersistenceAdapter({
    required this.store,
    this.codec = const ChatSessionSnapshotJsonCodec(),
  });

  Future<void> saveSnapshot(ChatSessionSnapshot snapshot) {
    return store.writeSnapshot(
      snapshot.chatId,
      codec.encodeSnapshot(snapshot),
    );
  }

  Future<void> saveSession(ChatSession session) {
    return saveSnapshot(session.exportSnapshot());
  }

  Future<void> saveController(ChatController controller) {
    return saveSnapshot(controller.exportSnapshot());
  }

  Future<ChatSessionSnapshot?> loadSnapshot(String chatId) async {
    final envelope = await store.readSnapshot(chatId);
    if (envelope == null) {
      return null;
    }

    return codec.decodeSnapshot(envelope);
  }

  Future<void> deleteSnapshot(String chatId) {
    return store.deleteSnapshot(chatId);
  }

  Future<T?> restoreSession<T extends ChatSession>(
    String chatId, {
    required T Function(ChatSessionSnapshot snapshot) createSession,
  }) async {
    final snapshot = await loadSnapshot(chatId);
    if (snapshot == null) {
      return null;
    }

    return createSession(snapshot);
  }

  Future<ChatController?> restoreController(
    String chatId, {
    required ChatController Function(ChatSessionSnapshot snapshot)
        createController,
  }) async {
    final snapshot = await loadSnapshot(chatId);
    if (snapshot == null) {
      return null;
    }

    return createController(snapshot);
  }
}
