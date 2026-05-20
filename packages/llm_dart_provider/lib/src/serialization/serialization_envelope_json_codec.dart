import '../common/json_codec_common.dart';
import 'serialization_protocol.dart';

final class SerializationEnvelopeJsonCodec {
  const SerializationEnvelopeJsonCodec();

  JsonMap encode({
    required String kind,
    required JsonMap data,
  }) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': kind,
      'data': data,
    };
  }

  JsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    final root = asJsonMap(envelope, path: r'$');
    final schemaVersion = asJsonString(
      root['schemaVersion'],
      path: r'$.schemaVersion',
    );
    if (schemaVersion != llmDartJsonSchemaVersion) {
      throw FormatException(
        'Unsupported llm_dart JSON schema version "$schemaVersion".',
      );
    }

    final kind = asJsonString(root['kind'], path: r'$.kind');
    if (kind != expectedKind) {
      throw FormatException(
        'Expected envelope kind "$expectedKind", received "$kind".',
      );
    }

    return asJsonMap(root['data'], path: r'$.data');
  }
}
