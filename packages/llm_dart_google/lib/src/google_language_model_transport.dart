import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'google_language_model_support.dart';
import 'google_model_settings.dart';

TransportRequest buildGoogleLanguageModelTransportRequest({
  required String baseUrl,
  required String modelId,
  required GenerateTextRequest request,
  required bool stream,
  required Object? body,
  required String apiKey,
  required GoogleChatModelSettings settings,
}) {
  return TransportRequest(
    uri: resolveGoogleLanguageModelRouteUri(
      baseUrl: baseUrl,
      modelId: modelId,
      stream: stream,
    ),
    method: TransportMethod.post,
    headers: buildGoogleRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      stream: stream,
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

Uri resolveGoogleLanguageModelRouteUri({
  required String baseUrl,
  required String modelId,
  required bool stream,
}) {
  final normalizedBaseUrl = normalizeGoogleBaseUrl(baseUrl);
  final action = stream ? 'streamGenerateContent?alt=sse' : 'generateContent';
  return Uri.parse('$normalizedBaseUrl/models/$modelId:$action');
}
