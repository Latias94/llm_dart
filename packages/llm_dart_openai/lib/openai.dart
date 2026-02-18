/// OpenAI provider package entrypoint.
///
/// This file intentionally mirrors the "provider package" shape used by other
/// `llm_dart_*` providers (e.g. `google.dart`, `ollama.dart`):
/// - exports the provider's public config/provider and common capability modules
/// - exposes `createOpenAI(...)` AI SDK-style provider factory
///
/// Advanced, provider-specific APIs are opt-in and should be imported explicitly:
/// - `package:llm_dart_openai/assistants.dart`
/// - `package:llm_dart_openai/responses.dart`
/// - other endpoint-level modules (files/models/moderation/completion)
library;

import 'config.dart';
import 'provider.dart';
import 'src/openai_provider_v3.dart';

// Core exports
export 'config.dart';
export 'provider.dart';

// Common capability modules (task-first)
export 'chat.dart';
export 'embeddings.dart';
export 'audio.dart';
export 'images.dart';

export 'src/openai_provider_v3.dart'
    show OpenAIProviderV3, OpenAIProviderSettings;

/// Create an OpenAI provider (AI SDK v3 style).
OpenAIProviderV3 createOpenAI({
  required Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  String providerId = 'openai',
  String providerName = 'OpenAI',
  OpenAIProvider Function(OpenAIConfig config)? providerFactory,
}) {
  return OpenAIProviderV3(
    OpenAIProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      providerId: providerId,
      providerName: providerName,
      providerFactory: providerFactory,
    ),
  );
}

/// Alias for `createOpenAI(...)` (upstream parity).
OpenAIProviderV3 openai({
  required Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  String providerId = 'openai',
  String providerName = 'OpenAI',
  OpenAIProvider Function(OpenAIConfig config)? providerFactory,
}) =>
    createOpenAI(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      providerId: providerId,
      providerName: providerName,
      providerFactory: providerFactory,
    );
