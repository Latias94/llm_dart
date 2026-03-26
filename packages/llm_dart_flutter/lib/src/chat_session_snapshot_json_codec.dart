import 'package:llm_dart_core/llm_dart_core.dart';

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
        'error': _encodeError(snapshot.error),
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
      error: data['error'],
    );
  }

  Object? _encodeError(Object? error) {
    try {
      return _ensureJsonValue(error, path: r'$.error');
    } on FormatException {
      return error == null
          ? null
          : {
              'type': 'unserializable-error',
              'runtimeType': error.runtimeType.toString(),
              'message': '$error',
            };
    }
  }
}

Object? _ensureJsonValue(
  Object? value, {
  required String path,
}) {
  return switch (value) {
    null || bool() || num() || String() => value,
    List() => value
        .asMap()
        .entries
        .map(
          (entry) => _ensureJsonValue(
            entry.value,
            path: '$path[${entry.key}]',
          ),
        )
        .toList(growable: false),
    Map() => value.map((key, nestedValue) {
        if (key is! String) {
          throw FormatException('Expected string key at $path.');
        }

        return MapEntry(
          key,
          _ensureJsonValue(nestedValue, path: '$path.$key'),
        );
      }),
    _ => throw FormatException(
        'Unsupported non-JSON value at $path: ${value.runtimeType}',
      ),
  };
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
