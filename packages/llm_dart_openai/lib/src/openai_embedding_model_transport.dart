import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_model_settings.dart';
import 'openai_non_text_model_support.dart';

TransportRequest buildOpenAIEmbeddingTransportRequest({
  required String baseUrl,
  required EmbedRequest request,
  required Object? body,
  required Map<String, String> defaultHeaders,
}) {
  return TransportRequest(
    uri: resolveOpenAIEmbeddingRouteUri(baseUrl: baseUrl),
    method: TransportMethod.post,
    headers: buildOpenAIEmbeddingRequestHeaders(
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

Uri resolveOpenAIEmbeddingRouteUri({required String baseUrl}) {
  return Uri.parse('$baseUrl/embeddings');
}

Map<String, String> buildOpenAIEmbeddingDefaultHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required OpenAIEmbeddingModelSettings settings,
}) {
  return buildOpenAIFamilyDefaultHeaders(
    profile: profile,
    apiKey: apiKey,
    organization: settings.organization,
    project: settings.project,
    headers: settings.headers,
  );
}

Map<String, String> buildOpenAIEmbeddingRequestHeaders({
  required Map<String, String> defaultHeaders,
  Map<String, String>? extraHeaders,
}) {
  return {
    ...defaultHeaders,
    'content-type': 'application/json',
    'accept': 'application/json',
    if (extraHeaders != null) ...extraHeaders,
  };
}
