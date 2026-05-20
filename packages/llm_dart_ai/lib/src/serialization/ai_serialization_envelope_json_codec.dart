import 'package:llm_dart_provider/llm_dart_provider.dart' as provider;

final class AiSerializationEnvelopeJsonCodec {
  const AiSerializationEnvelopeJsonCodec();

  provider.JsonMap encode({
    required String kind,
    required provider.JsonMap data,
  }) {
    return {
      'schemaVersion': provider.llmDartJsonSchemaVersion,
      'kind': kind,
      'data': data,
    };
  }

  provider.JsonMap decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    final root = provider.asJsonMap(envelope, path: r'$');
    final schemaVersion = provider.asJsonString(
      root['schemaVersion'],
      path: r'$.schemaVersion',
    );
    if (schemaVersion != provider.llmDartJsonSchemaVersion) {
      throw FormatException(
        'Unsupported llm_dart AI JSON schema version "$schemaVersion".',
      );
    }

    final kind = provider.asJsonString(root['kind'], path: r'$.kind');
    if (kind != expectedKind) {
      throw FormatException(
        'Expected envelope kind "$expectedKind", received "$kind".',
      );
    }

    return provider.asJsonMap(root['data'], path: r'$.data');
  }
}
