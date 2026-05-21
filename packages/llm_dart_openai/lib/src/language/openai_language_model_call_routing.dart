import 'package:llm_dart_provider/llm_dart_provider.dart';

import '../provider/openai_family_profile.dart';
import '../provider/openai_family_route_policy.dart';
import '../provider/resolved_openai_chat_settings.dart';
import '../provider/resolved_openai_options.dart';

final class ResolvedOpenAILanguageModelCall {
  final OpenAIRequestRoute route;
  final String requestModelId;
  final ResolvedOpenAIGenerateTextOptions providerOptions;

  const ResolvedOpenAILanguageModelCall({
    required this.route,
    required this.requestModelId,
    required this.providerOptions,
  });

  bool get usesResponsesApi => route == OpenAIRequestRoute.responses;
}

ResolvedOpenAILanguageModelCall resolveOpenAILanguageModelCall({
  required GenerateTextRequest request,
  required String modelId,
  required OpenAIFamilyProfile profile,
  required ResolvedOpenAIChatModelSettings settings,
}) {
  final providerOptions = _resolveOpenAIProviderOptions(
    request: request,
    profile: profile,
    settings: settings,
  );
  final requestModelId = _resolveOpenAIRequestModelId(
    modelId: modelId,
    profile: profile,
    settings: settings,
    providerOptions: providerOptions,
  );

  return ResolvedOpenAILanguageModelCall(
    route: profile.routePolicy.resolveLanguageModelRoute(settings),
    requestModelId: requestModelId,
    providerOptions: providerOptions,
  );
}

ResolvedOpenAIGenerateTextOptions _resolveOpenAIProviderOptions({
  required GenerateTextRequest request,
  required OpenAIFamilyProfile profile,
  required ResolvedOpenAIChatModelSettings settings,
}) {
  return profile.optionResolver.resolveInvocationOptions(
    options: request.callOptions.providerOptions,
    sharedResponseFormat: request.options.responseFormat,
    modelSettings: settings,
  );
}

String _resolveOpenAIRequestModelId({
  required String modelId,
  required OpenAIFamilyProfile profile,
  required ResolvedOpenAIChatModelSettings settings,
  required ResolvedOpenAIGenerateTextOptions providerOptions,
}) {
  return profile.optionResolver.resolveRequestModelId(
    modelId: modelId,
    modelSettings: settings,
    invocationOptions: providerOptions,
  );
}
