import 'package:llm_dart_ai/llm_dart_ai.dart';

final class HttpChatTransportEnvelopeJsonCodec {
  static const _codec = VersionedJsonEnvelopeCodec(
    unsupportedSchemaVersionDescription: 'HTTP chat transport schema version',
  );

  const HttpChatTransportEnvelopeJsonCodec();

  Map<String, Object?> encode({
    required String kind,
    required Map<String, Object?> data,
  }) {
    return _codec.encode(kind: kind, data: data);
  }

  Map<String, Object?> decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    return _codec.decode(envelope, expectedKind: expectedKind);
  }
}
