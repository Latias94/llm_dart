import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_model_settings.dart';

enum GoogleImageRequestRoute {
  predict('predict'),
  generateContent('generateContent');

  const GoogleImageRequestRoute(this.action);

  final String action;
}

TransportRequest buildGoogleImageTransportRequest({
  required String baseUrl,
  required String modelId,
  required GoogleImageRequestRoute route,
  required CallOptions callOptions,
  required Object? body,
  required String apiKey,
  required GoogleImageModelSettings settings,
}) {
  return TransportRequest(
    uri: resolveGoogleImageRouteUri(
      baseUrl: baseUrl,
      modelId: modelId,
      route: route,
    ),
    method: TransportMethod.post,
    headers: buildGoogleImageRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      extraHeaders: callOptions.headers,
    ),
    body: body,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: bindProviderCancellationToTransport(
      callOptions.cancellation,
    ),
    responseType: TransportResponseType.json,
  );
}

Uri resolveGoogleImageRouteUri({
  required String baseUrl,
  required String modelId,
  required GoogleImageRequestRoute route,
}) {
  return Uri.parse(
    '${normalizeGoogleImageBaseUrl(baseUrl)}/models/$modelId:${route.action}',
  );
}

Map<String, String> buildGoogleImageRequestHeaders({
  required String apiKey,
  required GoogleImageModelSettings settings,
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

String normalizeGoogleImageBaseUrl(String baseUrl) {
  return baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
}
