import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

final class HttpChatTransportEnvelopeJsonCodec {
  const HttpChatTransportEnvelopeJsonCodec();

  Map<String, Object?> encode({
    required String kind,
    required Map<String, Object?> data,
  }) {
    return {
      'schemaVersion': llmDartJsonSchemaVersion,
      'kind': kind,
      'data': data,
    };
  }

  Map<String, Object?> decode(
    Object? envelope, {
    required String expectedKind,
  }) {
    final root = HttpChatTransportJson.asMap(envelope, path: r'$');
    final schemaVersion = HttpChatTransportJson.asString(
      root['schemaVersion'],
      path: r'$.schemaVersion',
    );
    if (schemaVersion != llmDartJsonSchemaVersion) {
      throw FormatException(
        'Unsupported HTTP chat transport schema version "$schemaVersion".',
      );
    }

    final kind = HttpChatTransportJson.asString(root['kind'], path: r'$.kind');
    if (kind != expectedKind) {
      throw FormatException(
        'Expected envelope kind "$expectedKind", received "$kind".',
      );
    }

    return HttpChatTransportJson.asMap(root['data'], path: r'$.data');
  }
}
