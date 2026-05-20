import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_session_snapshot_envelope_json_codec.dart';
import 'chat_session_snapshot.dart';
import 'chat_state.dart';

final class ChatSessionSnapshotJsonCodec {
  static const envelopeKind = 'chat-session-snapshot';

  final PromptJsonCodec promptCodec;
  final ChatUiJsonCodec messageCodec;

  const ChatSessionSnapshotJsonCodec({
    this.promptCodec = const PromptJsonCodec(),
    this.messageCodec = const ChatUiJsonCodec(),
  });

  Map<String, Object?> encodeSnapshot(ChatSessionSnapshot snapshot) {
    return const ChatSessionSnapshotEnvelopeJsonCodec().encode(
      kind: envelopeKind,
      data: {
        'chatId': snapshot.chatId,
        'prompt': promptCodec.encodeMessages(snapshot.prompt),
        'messages': messageCodec.encodeMessages(snapshot.messages),
        'status': snapshot.status.name,
        'error': snapshot.error?.toJsonMap(path: r'$.data.error'),
      },
    );
  }

  ChatSessionSnapshot decodeSnapshot(Object? envelope) {
    final data = const ChatSessionSnapshotEnvelopeJsonCodec().decode(
      envelope,
      expectedKind: envelopeKind,
    );
    return ChatSessionSnapshot(
      chatId:
          chatSessionSnapshotJsonString(data['chatId'], path: r'$.data.chatId'),
      prompt: promptCodec.decodeMessages(data['prompt']),
      messages: messageCodec.decodeMessages(data['messages']),
      status: ChatStatus.values.byName(
        chatSessionSnapshotJsonString(data['status'], path: r'$.data.status'),
      ),
      error: data['error'] == null
          ? null
          : ModelError.fromJson(data['error'], path: r'$.data.error'),
    );
  }
}
