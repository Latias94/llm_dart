import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_generate_text_options.dart';
import 'google_model_settings.dart';
import 'google_response_format.dart';

GoogleGenerateTextOptions resolveGoogleProviderOptions(
  GenerateTextRequest request,
) {
  final options = request.callOptions.providerOptions;
  final sharedResponseFormat = resolveGoogleSharedResponseFormat(
    request.options.responseFormat,
  );

  final resolved = resolveProviderInvocationOptions<GoogleGenerateTextOptions>(
        options,
        parameterName: 'providerOptions',
        expectedTypeName: 'GoogleGenerateTextOptions',
        usageContext: 'Google language models',
      ) ??
      const GoogleGenerateTextOptions();

  if (request.options.responseFormat != null &&
      resolved.responseFormat != null) {
    throw ArgumentError(
      'GenerateTextOptions.responseFormat and GoogleGenerateTextOptions.responseFormat cannot both be set.',
    );
  }

  if (sharedResponseFormat == null) {
    return resolved;
  }

  return resolved.copyWith(responseFormat: sharedResponseFormat);
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
