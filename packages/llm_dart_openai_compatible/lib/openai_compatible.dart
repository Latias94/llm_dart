/// OpenAI-compatible provider package entrypoint.
///
/// Mirrors the Vercel AI SDK `@ai-sdk/openai-compatible` shape:
/// - `createOpenAICompatible({ baseUrl, name, ... })` returns a callable provider
/// - calling the provider with a model id returns a language model
library;

import 'src/openai_compatible_provider_v3.dart';

export 'src/openai_compatible_provider_v3.dart'
    show
        OpenAICompatibleProviderV3,
        OpenAICompatibleProviderSettings,
        OpenAICompatibleProviderClientFactory;

/// Create an OpenAI-compatible provider (AI SDK v3 style).
OpenAICompatibleProviderV3 createOpenAICompatible({
  required String baseUrl,
  required String name,
  Object? apiKey,
  Map<String, String>? headers,
  Map<String, String>? queryParams,
  Duration? timeout,
  String? endpointPrefix,
  bool? includeUsage,
  bool? supportsStructuredOutputs,
  OpenAICompatibleProviderClientFactory? clientFactory,
}) {
  return OpenAICompatibleProviderV3(
    OpenAICompatibleProviderSettings(
      baseUrl: baseUrl,
      name: name,
      apiKey: apiKey,
      headers: headers,
      queryParams: queryParams,
      timeout: timeout,
      endpointPrefix: endpointPrefix,
      includeUsage: includeUsage,
      supportsStructuredOutputs: supportsStructuredOutputs,
      clientFactory: clientFactory,
    ),
  );
}

