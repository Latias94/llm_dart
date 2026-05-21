import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_assistants_transport.dart';
import '../common/openai_json_support.dart';

Future<T> sendOpenAIAssistantsJsonModel<T>({
  required TransportClient transport,
  required OpenAIAssistantsTransportSupport requestSupport,
  required Uri uri,
  required TransportMethod method,
  required String responseName,
  required T Function(Map<String, Object?> json) decode,
  Object? body,
  Duration? timeout,
  int? maxRetries,
  TransportCancellation? cancellation,
  Map<String, String>? headers,
  bool contentType = false,
}) async {
  return sendProviderModelRequest(
    transport: transport,
    request: requestSupport.jsonRequest(
      uri: uri,
      method: method,
      extraHeaders: headers,
      contentType: contentType,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
    ),
    decode: (body, _) {
      return decode(
        decodeOpenAIJsonObject(body, responseName: responseName),
      );
    },
  );
}
