import 'package:llm_dart_ai/llm_dart_ai.dart';

typedef ChatSessionSnapshotJsonMap = Map<String, Object?>;

final class ChatSessionSnapshotEnvelopeJsonCodec {
  const ChatSessionSnapshotEnvelopeJsonCodec();

  ChatSessionSnapshotJsonMap encode({
    required String kind,
    required ChatSessionSnapshotJsonMap data,
  }) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': kind,
      'data': data,
    };
  }

  ChatSessionSnapshotJsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    final root = chatSessionSnapshotJsonMap(envelope, path: r'$');
    final schemaVersion = chatSessionSnapshotJsonString(
      root['schemaVersion'],
      path: r'$.schemaVersion',
    );
    if (schemaVersion != llmDartJsonSchemaVersion) {
      throw FormatException(
        'Unsupported chat session snapshot schema version "$schemaVersion".',
      );
    }

    final kind = chatSessionSnapshotJsonString(root['kind'], path: r'$.kind');
    if (kind != expectedKind) {
      throw FormatException(
        'Expected envelope kind "$expectedKind", received "$kind".',
      );
    }

    return chatSessionSnapshotJsonMap(root['data'], path: r'$.data');
  }
}

ChatSessionSnapshotJsonMap chatSessionSnapshotJsonMap(
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

String chatSessionSnapshotJsonString(
  Object? value, {
  required String path,
}) {
  if (value is! String) {
    throw FormatException('Expected string at $path.');
  }

  return value;
}
