/// OpenAI provider package entrypoint.
///
/// This file intentionally mirrors the "provider package" shape used by other
/// `llm_dart_*` providers (e.g. `google.dart`, `ollama.dart`):
/// - exports the provider's public config/provider and common capability modules
/// - exposes `createOpenAIProvider(...)` convenience constructor
///
/// Advanced, provider-specific APIs are opt-in and should be imported explicitly:
/// - `package:llm_dart_openai/assistants.dart`
/// - `package:llm_dart_openai/responses.dart`
/// - other endpoint-level modules (files/models/moderation/completion)
library;

import 'config.dart';
import 'provider.dart';
import 'defaults.dart';

// Core exports
export 'config.dart';
export 'provider.dart';

// Common capability modules (task-first)
export 'chat.dart';
export 'embeddings.dart';
export 'audio.dart';
export 'images.dart';

/// Create an OpenAI provider with default settings.
OpenAIProvider createOpenAIProvider({
  required String apiKey,
  String model = openaiDefaultModel,
  String baseUrl = openaiBaseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}
