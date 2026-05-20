import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_model_settings.dart';

TransportRequest buildGoogleEmbeddingTransportRequest({
  required String baseUrl,
  required String modelId,
  required EmbedRequest request,
  required bool batch,
  required Object? body,
  required String apiKey,
  required GoogleEmbeddingModelSettings settings,
}) {
  return TransportRequest(
    uri: resolveGoogleEmbeddingRouteUri(
      baseUrl: baseUrl,
      modelId: modelId,
      batch: batch,
    ),
    method: TransportMethod.post,
    headers: buildGoogleEmbeddingRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      extraHeaders: request.callOptions.headers,
    ),
    body: body,
    timeout: request.callOptions.timeout,
    maxRetries: request.callOptions.maxRetries,
    cancellation: bindProviderCancellationToTransport(
      request.callOptions.cancellation,
    ),
    responseType: TransportResponseType.json,
  );
}

Uri resolveGoogleEmbeddingRouteUri({
  required String baseUrl,
  required String modelId,
  required bool batch,
}) {
  final normalizedBaseUrl = normalizeGoogleEmbeddingBaseUrl(baseUrl);
  final action = batch ? 'batchEmbedContents' : 'embedContent';
  return Uri.parse('$normalizedBaseUrl/models/$modelId:$action');
}

Map<String, String> buildGoogleEmbeddingRequestHeaders({
  required String apiKey,
  required GoogleEmbeddingModelSettings settings,
  Map<String, String>? extraHeaders,
}) {
  return {
    'x-goog-api-key': apiKey,
    'content-type': 'application/json',
    'accept': 'application/json',
    ...settings.headers,
    if (extraHeaders != null) ...extraHeaders,
  };
}

String normalizeGoogleEmbeddingBaseUrl(String baseUrl) {
  return baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
}
