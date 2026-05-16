import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_profile.dart';
import 'openai_family_option_resolver.dart';
import 'openai_response_format.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';

enum OpenAIRequestRoute {
  responses,
  chatCompletions,
}

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
  final providerOptions = resolveOpenAIProviderOptions(
    request: request,
    profile: profile,
    settings: settings,
  );
  final requestModelId = resolveOpenAIRequestModelId(
    modelId: modelId,
    profile: profile,
    settings: settings,
    providerOptions: providerOptions,
  );

  return ResolvedOpenAILanguageModelCall(
    route: settings.common.useResponsesApi && profile.supportsResponsesApi
        ? OpenAIRequestRoute.responses
        : OpenAIRequestRoute.chatCompletions,
    requestModelId: requestModelId,
    providerOptions: providerOptions,
  );
}

ResolvedOpenAIGenerateTextOptions resolveOpenAIProviderOptions({
  required GenerateTextRequest request,
  required OpenAIFamilyProfile profile,
  required ResolvedOpenAIChatModelSettings settings,
}) {
  return openAIFamilyOptionResolverFor(profile).resolveInvocationOptions(
    options: request.callOptions.providerOptions,
    sharedResponseFormat: request.options.responseFormat,
    modelSettings: settings,
  );
}

ResolvedOpenAIChatModelSettings resolveOpenAIModelSettingsForProfile(
  OpenAIFamilyProfile profile,
  ProviderModelOptions settings,
) {
  return openAIFamilyOptionResolverFor(profile).resolveModelSettings(settings);
}

String resolveOpenAIRequestModelId({
  required String modelId,
  required OpenAIFamilyProfile profile,
  required ResolvedOpenAIChatModelSettings settings,
  required ResolvedOpenAIGenerateTextOptions providerOptions,
}) {
  return openAIFamilyOptionResolverFor(profile).resolveRequestModelId(
    modelId: modelId,
    modelSettings: settings,
    invocationOptions: providerOptions,
  );
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

Map<String, Object?> decodeOpenAIJsonObject(Object? body) {
  if (body is Map<String, Object?>) {
    return body;
  }

  if (body is Map) {
    return Map<String, Object?>.from(body);
  }

  if (body is String) {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  }

  throw StateError(
    'Expected an OpenAI JSON object response but received ${body.runtimeType}.',
  );
}

OpenAIJsonSchemaResponseFormat? resolveOpenAISharedResponseFormat(
  ResponseFormat? responseFormat,
) {
  return resolveOpenAIFamilySharedResponseFormat(responseFormat);
}
