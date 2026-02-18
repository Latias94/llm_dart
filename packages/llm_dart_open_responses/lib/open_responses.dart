/// Open Responses provider package entrypoint.
///
/// Mirrors the Vercel AI SDK `@ai-sdk/open-responses` shape:
/// - `createOpenResponses({ name, url })` returns a provider function
/// - calling the provider with a model id returns a language model
///
/// Notes (Dart-flavored):
/// - The returned model implements `ChatCapability` and streams `LLMStreamPart`.
/// - The provider talks to Open Responses-compatible endpoints that expose an
///   OpenAI Responses-like API (e.g. `.../v1/responses`).
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'src/open_responses_provider.dart';

export 'src/open_responses_provider.dart'
    show
        OpenResponsesProvider,
        OpenResponsesProviderSettings;

/// Create an Open Responses provider factory.
OpenResponsesProvider createOpenResponses({
  required String name,
  required String url,
  String? apiKey,
  Map<String, String>? headers,
  Duration? timeout,
}) {
  return OpenResponsesProvider(
    OpenResponsesProviderSettings(
      name: name,
      url: url,
      apiKey: apiKey,
      headers: headers,
      timeout: timeout,
    ),
  );
}

/// Convenience: resolve a model from a provider factory.
///
/// This exists mostly for symmetry with other llm_dart providers that expose
/// `createXProvider(...)` helpers.
ChatCapability openResponsesModel(
  OpenResponsesProvider provider,
  String modelId,
) =>
    provider(modelId);
