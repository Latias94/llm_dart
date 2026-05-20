import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_model_settings.dart';
import 'openai_non_text_model_support.dart';

enum OpenAIImageRequestRoute {
  generation('/images/generations'),
  edit('/images/edits');

  const OpenAIImageRequestRoute(this.path);

  final String path;
}

TransportRequest buildOpenAIImageTransportRequest({
  required String baseUrl,
  required OpenAIImageRequestRoute route,
  required CallOptions callOptions,
  required Object? body,
  required Map<String, String> defaultHeaders,
  required String contentType,
}) {
  return TransportRequest(
    uri: resolveOpenAIImageRouteUri(baseUrl: baseUrl, route: route),
    method: TransportMethod.post,
    headers: buildOpenAIImageRequestHeaders(
      defaultHeaders: defaultHeaders,
      contentType: contentType,
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

Uri resolveOpenAIImageRouteUri({
  required String baseUrl,
  required OpenAIImageRequestRoute route,
}) {
  return Uri.parse('$baseUrl${route.path}');
}

Map<String, String> buildOpenAIImageDefaultHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required OpenAIImageModelSettings settings,
}) {
  return buildOpenAIFamilyDefaultHeaders(
    profile: profile,
    apiKey: apiKey,
    organization: settings.organization,
    project: settings.project,
    headers: settings.headers,
  );
}

Map<String, String> buildOpenAIImageRequestHeaders({
  required Map<String, String> defaultHeaders,
  required String contentType,
  Map<String, String>? extraHeaders,
}) {
  return {
    ...defaultHeaders,
    'content-type': contentType,
    'accept': 'application/json',
    if (extraHeaders != null) ...extraHeaders,
  };
}
