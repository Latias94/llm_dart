import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'chat_session_snapshot.dart';
import 'chat_state.dart';

typedef _JsonMap = Map<String, Object?>;

final class ChatSessionSnapshotJsonCodec {
  static const envelopeKind = 'chat-session-snapshot';

  final PromptJsonCodec promptCodec;
  final ChatUiJsonCodec messageCodec;

  const ChatSessionSnapshotJsonCodec({
    this.promptCodec = const PromptJsonCodec(),
    this.messageCodec = const ChatUiJsonCodec(),
  });

  Map<String, Object?> encodeSnapshot(ChatSessionSnapshot snapshot) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': envelopeKind,
      'data': {
        'chatId': snapshot.chatId,
        'prompt': promptCodec.encodeMessages(snapshot.prompt),
        'messages': messageCodec.encodeMessages(snapshot.messages),
        'status': snapshot.status.name,
        'error': snapshot.error?.toJsonMap(path: r'$.data.error'),
      },
    };
  }

  ChatSessionSnapshot decodeSnapshot(Object? envelope) {
    final root = _asJsonMap(envelope, path: r'$');
    final kind = _asJsonString(root['kind'], path: r'$.kind');
    if (kind != envelopeKind) {
      throw FormatException(
        'Expected envelope kind "$envelopeKind", received "$kind".',
      );
    }

    final data = _asJsonMap(root['data'], path: r'$.data');
    return ChatSessionSnapshot(
      chatId: _asJsonString(data['chatId'], path: r'$.data.chatId'),
      prompt: promptCodec.decodeMessages(data['prompt']),
      messages: messageCodec.decodeMessages(data['messages']),
      status: ChatStatus.values.byName(
        _asJsonString(data['status'], path: r'$.data.status'),
      ),
      error: data['error'] == null
          ? null
          : ModelError.fromJson(data['error'], path: r'$.data.error'),
    );
  }
}

_JsonMap _asJsonMap(
  Object? value, {
  required String path,
}) {
  if (value is! Map) {
    throw FormatException('Expected JSON object at $path.');
  }

  return value.map((key, nestedValue) {
    if (key is! String) {
      throw FormatException('Expected string key at $path.');
    }

    return MapEntry(key, nestedValue);
  });
}

String _asJsonString(
  Object? value, {
  required String path,
}) {
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }

  return value;
}
