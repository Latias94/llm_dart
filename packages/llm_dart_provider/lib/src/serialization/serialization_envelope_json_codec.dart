import '../common/json_codec_common.dart';
import 'versioned_json_envelope_codec.dart';

final class SerializationEnvelopeJsonCodec {
  static const _codec = VersionedJsonEnvelopeCodec();

  const SerializationEnvelopeJsonCodec();

  JsonMap encode({
    required String kind,
    required JsonMap data,
  }) {
    return _codec.encode(kind: kind, data: data);
  }

  JsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    return _codec.decode(envelope, expectedKind: expectedKind);
  }
}
