import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import 'openai_language_model_call_routing.dart';
import 'openai_language_model_route_adapter.dart';
import 'openai_language_model_route_adapters.dart';
import '../provider/openai_provider_support.dart';
import '../provider/resolved_openai_chat_settings.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

final class PreparedOpenAILanguageModelCall {
  final ResolvedOpenAILanguageModelCall call;
  final OpenAILanguageModelRouteAdapter routeAdapter;
  final TransportRequest transportRequest;
  final List<ModelWarning> warnings;

  const PreparedOpenAILanguageModelCall({
    required this.call,
    required this.routeAdapter,
    required this.transportRequest,
    required this.warnings,
  });
}

PreparedOpenAILanguageModelCall prepareOpenAILanguageModelCall({
  required GenerateTextRequest request,
  required String modelId,
  required String baseUrl,
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required ResolvedOpenAIChatModelSettings settings,
  required bool stream,
  required OpenAILanguageModelRouteAdapters routeAdapters,
}) {
  final call = resolveOpenAILanguageModelCall(
    request: request,
    modelId: modelId,
    profile: profile,
    settings: settings,
  );
  final routeAdapter = routeAdapters.resolve(call.route);
  final preparedRequest = routeAdapter.encodeRequest(
    call: call,
    request: request,
    stream: stream,
  );

  return PreparedOpenAILanguageModelCall(
    call: call,
    routeAdapter: routeAdapter,
    transportRequest: TransportRequest(
      uri: routeAdapter.resolveUri(baseUrl),
      method: TransportMethod.post,
      headers: buildOpenAIRequestHeaders(
        profile: profile,
        apiKey: apiKey,
        settings: settings,
        stream: stream,
        extraHeaders: request.callOptions.headers,
      ),
      body: preparedRequest.body,
      timeout: request.callOptions.timeout,
      maxRetries: request.callOptions.maxRetries,
      cancellation: bindProviderCancellationToTransport(
        request.callOptions.cancellation,
      ),
      responseType: TransportResponseType.json,
    ),
    warnings: preparedRequest.warnings,
  );
}
