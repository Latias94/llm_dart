import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

final class AiSerializationEnvelopeJsonCodec {
  static const _codec = provider.VersionedJsonEnvelopeCodec(
    unsupportedSchemaVersionDescription: 'llm_dart AI JSON schema version',
  );

  const AiSerializationEnvelopeJsonCodec();

  provider.JsonMap encode({
    required String kind,
    required provider.JsonMap data,
  }) {
    return _codec.encode(kind: kind, data: data);
  }

  provider.JsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    return _codec.decode(envelope, expectedKind: expectedKind);
  }
}
