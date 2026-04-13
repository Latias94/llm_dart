import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';

import 'google_options.dart';
import 'google_response_format.dart';

GoogleGenerateTextOptions resolveGoogleProviderOptions(
  GenerateTextRequest request,
) {
  final options = request.callOptions.providerOptions;
  final sharedResponseFormat = resolveGoogleSharedResponseFormat(
    request.options.responseFormat,
  );

  GoogleGenerateTextOptions resolved;
  if (options == null) {
    resolved = const GoogleGenerateTextOptions();
  } else if (options is GoogleGenerateTextOptions) {
    resolved = options;
  } else {
    throw ArgumentError.value(
      options,
      'providerOptions',
      'Expected GoogleGenerateTextOptions for Google language models.',
    );
  }

  if (request.options.responseFormat != null &&
      resolved.responseFormat != null) {
    throw ArgumentError(
      'GenerateTextOptions.responseFormat and GoogleGenerateTextOptions.responseFormat cannot both be set.',
    );
  }

  if (sharedResponseFormat == null) {
    return resolved;
  }

  return GoogleGenerateTextOptions(
    candidateCount: resolved.candidateCount,
    thinkingBudgetTokens: resolved.thinkingBudgetTokens,
    thinkingLevel: resolved.thinkingLevel,
    includeThoughts: resolved.includeThoughts,
    responseModalities: resolved.responseModalities,
    cachedContent: resolved.cachedContent,
    safetySettings: resolved.safetySettings,
    tools: resolved.tools,
    includeServerSideToolInvocations: resolved.includeServerSideToolInvocations,
    responseFormat: sharedResponseFormat,
  );
}

Map<String, String> buildGoogleRequestHeaders({
  required String apiKey,
  required GoogleChatModelSettings settings,
  required bool stream,
  Map<String, String>? extraHeaders,
}) {
  return {
    'x-goog-api-key': apiKey,
    'content-type': 'application/json',
    'accept': stream ? 'text/event-stream' : 'application/json',
    ...settings.headers,
    if (extraHeaders != null) ...extraHeaders,
  };
}

Map<String, Object?> decodeGoogleJsonObject(Object? body) {
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
    'Expected a Google JSON object response but received ${body.runtimeType}.',
  );
}

String normalizeGoogleBaseUrl(String baseUrl) {
  return baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
}

GoogleJsonSchemaResponseFormat? resolveGoogleSharedResponseFormat(
  ResponseFormat? responseFormat,
) {
  return switch (responseFormat) {
    null || TextResponseFormat() => null,
    JsonResponseFormat(schema: final schema) => GoogleJsonSchemaResponseFormat(
        schema: schema.toJson(),
      ),
  };
}
