import 'package:llm_dart_chat/llm_dart_chat.dart' as chat;

import 'chat_controller.dart';

/// Flutter-aware persistence helper above chat session snapshots.
///
/// The shared snapshot codec and store contracts live in `llm_dart_chat`.
/// This adapter adds controller convenience methods without pulling Flutter
/// types into the pure Dart runtime package.
final class ChatPersistenceAdapter {
  final chat.ChatPersistenceStore store;
  final chat.ChatSessionSnapshotJsonCodec codec;

  late final chat.ChatPersistenceAdapter _adapter =
      chat.ChatPersistenceAdapter(
        store: store,
        codec: codec,
      );

  ChatPersistenceAdapter({
    required this.store,
    chat.ChatSessionSnapshotJsonCodec? codec,
  }) : codec = codec ?? const chat.ChatSessionSnapshotJsonCodec();

  Future<void> saveSnapshot(chat.ChatSessionSnapshot snapshot) {
    return _adapter.saveSnapshot(snapshot);
  }

  Future<void> saveSession(chat.ChatSession session) {
    return _adapter.saveSession(session);
  }

  Future<void> saveController(ChatController controller) {
    return saveSnapshot(controller.exportSnapshot());
  }

  Future<chat.ChatSessionSnapshot?> loadSnapshot(String chatId) {
    return _adapter.loadSnapshot(chatId);
  }

  Future<void> deleteSnapshot(String chatId) {
    return _adapter.deleteSnapshot(chatId);
  }

  Future<T?> restoreSession<T extends chat.ChatSession>(
    String chatId, {
    required T Function(chat.ChatSessionSnapshot snapshot) createSession,
  }) {
    return _adapter.restoreSession(
      chatId,
      createSession: createSession,
    );
  }

  Future<T?> restoreController<T extends ChatController>(
    String chatId, {
    required T Function(chat.ChatSessionSnapshot snapshot) createController,
  }) async {
    final snapshot = await loadSnapshot(chatId);
    if (snapshot == null) {
      return null;
    }

    return createController(snapshot);
  }
}
