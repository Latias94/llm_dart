import 'package:llm_dart_ai/llm_dart_ai.dart';

typedef ChatSessionSnapshotJsonMap = Map<String, Object?>;

final class ChatSessionSnapshotEnvelopeJsonCodec {
  static const _codec = VersionedJsonEnvelopeCodec(
    unsupportedSchemaVersionDescription: 'chat session snapshot schema version',
  );

  const ChatSessionSnapshotEnvelopeJsonCodec();

  ChatSessionSnapshotJsonMap encode({
    required String kind,
    required ChatSessionSnapshotJsonMap data,
  }) {
    return _codec.encode(kind: kind, data: data);
  }

  ChatSessionSnapshotJsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    return _codec.decode(envelope, expectedKind: expectedKind);
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
