import 'http_chat_transport_json_support.dart';
import 'http_chat_transport_request_payload.dart';

final class HttpChatTransportCallOptionsJsonCodec {
  const HttpChatTransportCallOptionsJsonCodec();

  HttpChatTransportJsonMap encode(
    HttpChatTransportCallOptionsPayload options,
  ) {
    return {
      if (options.timeout != null)
        'timeoutMilliseconds': options.timeout!.inMilliseconds,
      if (options.headers.isNotEmpty) 'headers': options.headers,
      if (options.maxRetries != null) 'maxRetries': options.maxRetries,
      if (options.providerOptions.isNotEmpty)
        'providerOptions': options.providerOptions,
    };
  }

  HttpChatTransportCallOptionsPayload decode(
    Object? value, {
    required String path,
  }) {
    if (value == null) {
      return HttpChatTransportCallOptionsPayload.empty;
    }

    final map = HttpChatTransportJson.asMap(value, path: path);
    final timeoutMilliseconds = HttpChatTransportJson.asNullableNonNegativeInt(
      map['timeoutMilliseconds'],
      path: '$path.timeoutMilliseconds',
    );

    return HttpChatTransportCallOptionsPayload(
      timeout: timeoutMilliseconds == null
          ? null
          : Duration(milliseconds: timeoutMilliseconds),
      headers: map['headers'] == null
          ? const {}
          : HttpChatTransportJson.asStringMap(
              map['headers'],
              path: '$path.headers',
            ),
      maxRetries: HttpChatTransportJson.asNullableNonNegativeInt(
        map['maxRetries'],
        path: '$path.maxRetries',
      ),
      providerOptions: map['providerOptions'] == null
          ? const {}
          : HttpChatTransportJson.asMap(
              map['providerOptions'],
              path: '$path.providerOptions',
            ),
    );
  }
}
