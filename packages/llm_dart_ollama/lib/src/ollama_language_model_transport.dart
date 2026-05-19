import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_model_settings.dart';

TransportRequest buildOllamaChatGenerateTransportRequest({
  required String baseUrl,
  required GenerateTextRequest request,
  required Object? body,
  required Map<String, String> defaultHeaders,
}) {
  return TransportRequest(
    uri: resolveOllamaChatRouteUri(baseUrl: baseUrl),
    method: TransportMethod.post,
    headers: buildOllamaChatRequestHeaders(
      defaultHeaders: defaultHeaders,
      extraHeaders: request.callOptions.headers,
    ),
    body: body,
    timeout: request.callOptions.timeout,
    maxRetries: request.callOptions.maxRetries,
    cancellation: request.callOptions.cancellation,
    responseType: TransportResponseType.json,
  );
}

TransportRequest buildOllamaChatStreamTransportRequest({
  required String baseUrl,
  required GenerateTextRequest request,
  required Object? body,
  required Map<String, String> defaultHeaders,
}) {
  return TransportRequest(
    uri: resolveOllamaChatRouteUri(baseUrl: baseUrl),
    method: TransportMethod.post,
    headers: buildOllamaChatRequestHeaders(
      defaultHeaders: defaultHeaders,
      accept: 'application/x-ndjson',
      extraHeaders: request.callOptions.headers,
    ),
    body: body,
    timeout: request.callOptions.timeout,
    maxRetries: request.callOptions.maxRetries,
    cancellation: request.callOptions.cancellation,
  );
}

Uri resolveOllamaChatRouteUri({required String baseUrl}) {
  return resolveOllamaUri(baseUrl, '/api/chat');
}

Map<String, String> buildOllamaChatDefaultHeaders({
  required String? apiKey,
  required OllamaChatModelSettings settings,
}) {
  return buildOllamaHeaders(
    apiKey: apiKey,
    contentType: 'application/json',
    headers: settings.headers,
  );
}

Map<String, String> buildOllamaChatRequestHeaders({
  required Map<String, String> defaultHeaders,
  String? accept,
  Map<String, String>? extraHeaders,
}) {
  return {
    ...defaultHeaders,
    if (accept != null) 'accept': accept,
    if (extraHeaders != null) ...extraHeaders,
  };
}
