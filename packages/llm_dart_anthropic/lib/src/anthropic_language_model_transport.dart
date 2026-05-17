import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_options.dart';

enum AnthropicLanguageModelRoute {
  messages,
  countTokens,
}

TransportRequest buildAnthropicLanguageModelTransportRequest({
  required String baseUrl,
  required AnthropicLanguageModelRoute route,
  required CallOptions callOptions,
  required bool stream,
  required Object? body,
  required String apiKey,
  required AnthropicChatModelSettings settings,
  required List<String> requestBetas,
}) {
  return TransportRequest(
    uri: resolveAnthropicLanguageModelRouteUri(
      baseUrl: baseUrl,
      route: route,
    ),
    method: TransportMethod.post,
    headers: buildAnthropicLanguageModelRequestHeaders(
      apiKey: apiKey,
      settings: settings,
      stream: stream,
      requestBetas: requestBetas,
      extraHeaders: callOptions.headers,
    ),
    body: body,
    timeout: callOptions.timeout,
    maxRetries: callOptions.maxRetries,
    cancellation: callOptions.cancellation,
    responseType: TransportResponseType.json,
  );
}

Uri resolveAnthropicLanguageModelRouteUri({
  required String baseUrl,
  required AnthropicLanguageModelRoute route,
}) {
  return switch (route) {
    AnthropicLanguageModelRoute.messages =>
      resolveAnthropicUri(baseUrl, 'messages'),
    AnthropicLanguageModelRoute.countTokens =>
      resolveAnthropicUri(baseUrl, 'messages/count_tokens'),
  };
}

Map<String, String> buildAnthropicLanguageModelRequestHeaders({
  required String apiKey,
  required AnthropicChatModelSettings settings,
  required bool stream,
  required List<String> requestBetas,
  Map<String, String>? extraHeaders,
}) {
  return buildAnthropicHeaders(
    apiKey: apiKey,
    anthropicVersion: settings.anthropicVersion,
    defaultHeaders: settings.headers,
    extraHeaders: extraHeaders,
    betaFeatures: [
      ...settings.betaFeatures,
      ...requestBetas,
    ],
    accept: stream ? 'text/event-stream' : 'application/json',
    includeJsonContentType: true,
  );
}
