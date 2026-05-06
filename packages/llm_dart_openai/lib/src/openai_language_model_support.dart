import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_family_profile.dart';
import 'openai_options.dart';
import 'openai_response_format.dart';
import 'openrouter_options.dart';
import 'resolved_openai_chat_settings.dart';
import 'resolved_openai_options.dart';
import 'xai_options.dart';

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
  final options = request.callOptions.providerOptions;
  final sharedResponseFormat = resolveOpenAISharedResponseFormat(
    request.options.responseFormat,
  );

  OpenAIGenerateTextOptions common = const OpenAIGenerateTextOptions();
  XAILiveSearchOptions? xaiSearch;

  if (options == null) {
    common = const OpenAIGenerateTextOptions();
  } else if (options is OpenAIGenerateTextOptions) {
    common = options;
  } else if (options is XAIGenerateTextOptions) {
    if (profile.providerId != 'xai') {
      throw ArgumentError.value(
        options,
        'providerOptions',
        'XAIGenerateTextOptions are only valid for xAI language models.',
      );
    }

    common = options.common;
    xaiSearch = options.search;
  } else {
    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected OpenAIGenerateTextOptions or profile-specific OpenAI-family provider options.',
    );
  }

  if (request.options.responseFormat != null && common.responseFormat != null) {
    throw ArgumentError(
      'GenerateTextOptions.responseFormat and OpenAIGenerateTextOptions.responseFormat cannot both be set.',
    );
  }

  if (common.builtInTools == null && settings.common.builtInTools.isNotEmpty) {
    common = common.copyWith(
      builtInTools: settings.common.builtInTools,
    );
  }

  if (sharedResponseFormat != null) {
    common = common.copyWith(
      responseFormat: sharedResponseFormat,
    );
  }

  return ResolvedOpenAIGenerateTextOptions(
    common: common,
    xaiSearch: xaiSearch,
  );
}

ResolvedOpenAIChatModelSettings resolveOpenAIModelSettingsForProfile(
  OpenAIFamilyProfile profile,
  ProviderModelOptions settings,
) {
  if (settings is OpenAIChatModelSettings) {
    return ResolvedOpenAIChatModelSettings(
      common: settings,
    );
  }

  if (settings is OpenRouterChatModelSettings) {
    if (profile.providerId != 'openrouter') {
      throw ArgumentError.value(
        settings,
        'settings',
        'OpenRouterChatModelSettings are only valid for OpenRouter language models.',
      );
    }

    return ResolvedOpenAIChatModelSettings(
      common: settings.common,
      openRouterSearch: settings.search,
    );
  }

  throw ArgumentError.value(
    settings,
    'settings',
    'Expected OpenAIChatModelSettings or profile-specific OpenAI-family model settings.',
  );
}

String resolveOpenAIRequestModelId({
  required String modelId,
  required OpenAIFamilyProfile profile,
  required ResolvedOpenAIChatModelSettings settings,
}) {
  final search = settings.openRouterSearch;
  if (search == null) {
    return modelId;
  }

  if (profile.providerId != 'openrouter') {
    return modelId;
  }

  return switch (search.mode) {
    OpenRouterSearchMode.onlineModel => withOpenRouterOnlineModel(modelId),
  };
}

String withOpenRouterOnlineModel(String modelId) {
  if (modelId.endsWith(':online')) {
    return modelId;
  }

  if (modelId.contains('deepseek-r1')) {
    throw UnsupportedError(
      'OpenRouter online-model shaping is not supported for DeepSeek R1 traffic.',
    );
  }

  return '$modelId:online';
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
  return switch (responseFormat) {
    null || TextResponseFormat() => null,
    JsonResponseFormat(
      schema: final schema,
      name: final name,
      description: final description,
      strict: final strict,
    ) =>
      OpenAIJsonSchemaResponseFormat(
        name: name ?? 'structured_output',
        description: description,
        schema: schema.toJson(),
        strict: strict,
      ),
  };
}
