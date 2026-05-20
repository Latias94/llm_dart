import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../common/openai_json_support.dart';
import 'openai_responses_lifecycle_transport.dart';

Future<T> sendOpenAIResponsesLifecycleJsonModel<T>({
  required TransportClient transport,
  required OpenAIResponsesLifecycleTransportSupport requestSupport,
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
  final response = await transport.send(
    requestSupport.jsonRequest(
      uri: uri,
      method: method,
      extraHeaders: headers,
      contentType: contentType,
      body: body,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
    ),
  );

  return decode(
    decodeOpenAIJsonObject(response.body, responseName: responseName),
  );
}
