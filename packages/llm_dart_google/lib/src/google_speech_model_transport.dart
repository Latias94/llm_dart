import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_options.dart';

TransportRequest buildGoogleSpeechTransportRequest({
  required String baseUrl,
  required String modelId,
  required CallOptions callOptions,
  required Object? body,
  required String apiKey,
  required GoogleSpeechModelSettings settings,
}) {
  return TransportRequest(
    uri: resolveGoogleSpeechGenerateContentUri(
      baseUrl: baseUrl,
      modelId: modelId,
    ),
    method: TransportMethod.post,
    headers: buildGoogleSpeechRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      extraHeaders: callOptions.headers,
    ),
    body: body,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: callOptions.cancellation,
    responseType: TransportResponseType.json,
  );
}

Uri resolveGoogleSpeechGenerateContentUri({
  required String baseUrl,
  required String modelId,
}) {
  return Uri.parse(
    '${normalizeGoogleSpeechBaseUrl(baseUrl)}/models/$modelId:generateContent',
  );
}

Map<String, String> buildGoogleSpeechRequestHeaders({
  required String apiKey,
  required GoogleSpeechModelSettings settings,
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

String normalizeGoogleSpeechBaseUrl(String baseUrl) {
  return baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
}
