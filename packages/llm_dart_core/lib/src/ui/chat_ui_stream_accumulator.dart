import 'chat_ui_accumulator.dart';
import 'chat_ui_message.dart';
import 'chat_ui_stream_chunk.dart';

final class ChatUiStreamAccumulator {
  final ChatUiRole role;
  final ChatUiAccumulatorOptions options;

  ChatUiAccumulator _messageAccumulator;

  factory ChatUiStreamAccumulator({
    required String messageId,
    ChatUiRole role = ChatUiRole.assistant,
    ChatUiMessage? seedMessage,
    ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
  }) {
    return ChatUiStreamAccumulator._(
      role: role,
      options: options,
      messageAccumulator: ChatUiAccumulator(
        messageId: messageId,
        role: role,
        seedMessage: seedMessage,
        options: options,
      ),
    );
  }

  ChatUiStreamAccumulator._({
    required this.role,
    required this.options,
    required ChatUiAccumulator messageAccumulator,
  }) : _messageAccumulator = messageAccumulator;

  ChatUiMessage get message => _messageAccumulator.message;

  ChatUiMessage apply(ChatUiStreamChunk chunk) {
    switch (chunk) {
      case ChatUiMessageStartChunk():
        return _applyMessagePatch(
          messageId: chunk.messageId,
          metadataPatch: chunk.metadata,
        );
      case ChatUiMessageMetadataChunk():
        return _applyMessagePatch(
          metadataPatch: chunk.metadata,
        );
      case ChatUiEventChunk():
        return _messageAccumulator.apply(chunk.event);
      case ChatUiDataPartChunk():
        return _messageAccumulator.applyDataPart(chunk.part);
      case ChatUiMessageFinishChunk():
        return _applyMessagePatch(
          metadataPatch: chunk.metadata,
        );
    }
  }

  Stream<ChatUiMessage> project(Stream<ChatUiStreamChunk> chunks) async* {
    await for (final chunk in chunks) {
      yield apply(chunk);
    }
  }

  ChatUiMessage _applyMessagePatch({
    String? messageId,
    Map<String, Object?> metadataPatch = const {},
  }) {
    final current = _messageAccumulator.message;
    final nextMessage = ChatUiMessage(
      id: messageId ?? current.id,
      role: current.role,
      parts: current.parts,
      metadata: {
        ...current.metadata,
        ...metadataPatch,
      },
    );

    _messageAccumulator = ChatUiAccumulator(
      messageId: nextMessage.id,
      role: role,
      seedMessage: nextMessage,
      options: options,
    );

    return _messageAccumulator.message;
  }
}

Stream<ChatUiMessage> projectChatUiStreamChunkStream(
  Stream<ChatUiStreamChunk> chunks, {
  required String messageId,
  ChatUiRole role = ChatUiRole.assistant,
  ChatUiMessage? seedMessage,
  ChatUiAccumulatorOptions options = const ChatUiAccumulatorOptions(),
}) {
  final accumulator = ChatUiStreamAccumulator(
    messageId: messageId,
    role: role,
    seedMessage: seedMessage,
    options: options,
  );

  return accumulator.project(chunks);
}
