import 'package:llm_dart_ai/llm_dart_ai.dart';

import 'http_chat_transport_json_support.dart';

final class HttpChatTransportProviderToolOptionsCodec {
  final List<ProviderToolOptionsJsonCodec> codecs;

  const HttpChatTransportProviderToolOptionsCodec({
    this.codecs = const [],
  });

  HttpChatTransportJsonMap encode(
    ProviderToolOptions options, {
    required String path,
  }) {
    for (final codec in codecs) {
      if (codec.canEncode(options)) {
        return {
          'type': codec.type,
          'data': codec.encode(options),
        };
      }
    }

    throw UnsupportedError(
      'Cannot serialize providerOptions at $path because no '
      'ProviderToolOptionsJsonCodec was registered for '
      '${options.runtimeType}.',
    );
  }

  ProviderToolOptions? decode(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return null;
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    final type = HttpChatTransportJson.asString(
      map['type'],
      path: '$path.type',
    );
    final data = HttpChatTransportJson.asMap(
      map['data'],
      path: '$path.data',
    );
    for (final codec in codecs) {
      if (codec.type == type) {
        return codec.decode(data);
      }
    }

    throw FormatException(
      'Unsupported providerOptions type "$type" at $path. Register a '
      'ProviderToolOptionsJsonCodec for this type.',
    );
  }
}
