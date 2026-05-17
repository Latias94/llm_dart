import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_language_model_support.dart';
import 'resolved_openai_chat_settings.dart';

TransportRequest buildOpenAILanguageModelTransportRequest({
  required String baseUrl,
  required OpenAIRequestRoute route,
  required GenerateTextRequest request,
  required bool stream,
  required Object? body,
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required ResolvedOpenAIChatModelSettings settings,
}) {
  return TransportRequest(
    uri: resolveOpenAILanguageModelRouteUri(
      baseUrl: baseUrl,
      route: route,
    ),
    method: TransportMethod.post,
    headers: buildOpenAIRequestHeaders(
      profile: profile,
      apiKey: apiKey,
      settings: settings,
      stream: stream,
      extraHeaders: request.callOptions.headers,
    ),
    body: body,
    timeout: request.callOptions.timeout,
    maxRetries: request.callOptions.maxRetries,
    cancellation: request.callOptions.cancellation,
    responseType: TransportResponseType.json,
  );
}

Uri resolveOpenAILanguageModelRouteUri({
  required String baseUrl,
  required OpenAIRequestRoute route,
}) {
  return switch (route) {
    OpenAIRequestRoute.responses => Uri.parse('$baseUrl/responses'),
    OpenAIRequestRoute.chatCompletions =>
      Uri.parse('$baseUrl/chat/completions'),
  };
}
