import '../common/json_codec_common.dart';
import 'serialization_protocol.dart';

final class VersionedJsonEnvelopeCodec {
  final String schemaVersion;
  final String unsupportedSchemaVersionDescription;

  const VersionedJsonEnvelopeCodec({
    this.schemaVersion = llmDartJsonSchemaVersion,
    this.unsupportedSchemaVersionDescription = 'llm_dart JSON schema version',
  });

  JsonMap encode({
    required String kind,
    required JsonMap data,
  }) {
    return {
      'schemaVersion': schemaVersion,
      'kind': kind,
      'data': data,
    };
  }

  JsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    final root = asJsonMap(envelope, path: r'$');
    final actualSchemaVersion = asJsonString(
      root['schemaVersion'],
      path: r'$.schemaVersion',
    );
    if (actualSchemaVersion != schemaVersion) {
      throw FormatException(
        'Unsupported $unsupportedSchemaVersionDescription '
        '"$actualSchemaVersion".',
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
