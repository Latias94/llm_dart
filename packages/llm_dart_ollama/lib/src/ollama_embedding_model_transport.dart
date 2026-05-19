import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'ollama_api.dart';
import 'ollama_model_settings.dart';

TransportRequest buildOllamaEmbeddingTransportRequest({
  required String baseUrl,
  required EmbedRequest request,
  required Object? body,
  required Map<String, String> defaultHeaders,
}) {
  return TransportRequest(
    uri: resolveOllamaEmbeddingRouteUri(baseUrl: baseUrl),
    method: TransportMethod.post,
    headers: buildOllamaEmbeddingRequestHeaders(
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

Uri resolveOllamaEmbeddingRouteUri({required String baseUrl}) {
  return resolveOllamaUri(baseUrl, '/api/embed');
}

Map<String, String> buildOllamaEmbeddingDefaultHeaders({
  required String? apiKey,
  required OllamaEmbeddingModelSettings settings,
}) {
  return buildOllamaHeaders(
    apiKey: apiKey,
    contentType: 'application/json',
    headers: settings.headers,
  );
}

Map<String, String> buildOllamaEmbeddingRequestHeaders({
  required Map<String, String> defaultHeaders,
  Map<String, String>? extraHeaders,
}) {
  return {
    ...defaultHeaders,
    if (extraHeaders != null) ...extraHeaders,
  };
}
