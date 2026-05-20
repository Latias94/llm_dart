import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_option_resolver.dart';
import 'openai_family_profile.dart';
import '../language/openai_response_format.dart';
import 'resolved_openai_chat_settings.dart';

ResolvedOpenAIChatModelSettings resolveOpenAIModelSettingsForProfile(
  OpenAIFamilyProfile profile,
  ProviderModelOptions settings,
) {
  return openAIFamilyOptionResolverFor(profile).resolveModelSettings(settings);
}

String withOpenRouterOnlineModel(String modelId) {
  return resolveOpenRouterOnlineModelId(modelId);
}

Map<String, String> buildOpenAIRequestHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required ResolvedOpenAIChatModelSettings settings,
  required bool stream,
  Map<String, String>? extraHeaders,
}) {
  final defaultHeaders = buildOpenAIDefaultHeaders(
    profile: profile,
    apiKey: apiKey,
    settings: settings,
  );

  return {
    ...defaultHeaders,
    'content-type': 'application/json',
    'accept': stream ? 'text/event-stream' : 'application/json',
    if (extraHeaders != null) ...extraHeaders,
  };
}

Map<String, String> buildOpenAIDefaultHeaders({
  required OpenAIFamilyProfile profile,
  required String apiKey,
  required ResolvedOpenAIChatModelSettings settings,
}) {
  return profile.buildHeaders(
    apiKey: apiKey,
    extraHeaders: {
      if (settings.common.organization case final organization?)
        'openai-organization': organization,
      if (settings.common.project case final project?)
        'openai-project': project,
      ...settings.common.headers,
    },
  );
}

OpenAIJsonSchemaResponseFormat? resolveOpenAISharedResponseFormat(
  ResponseFormat? responseFormat,
) {
  return resolveOpenAIFamilySharedResponseFormat(responseFormat);
}
