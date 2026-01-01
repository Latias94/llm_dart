/// OpenAI provider package entrypoint.
///
/// This file intentionally mirrors the "provider package" shape used by other
/// `llm_dart_*` providers (e.g. `google.dart`, `ollama.dart`):
/// - exports the provider's public config/client/provider and capability modules
/// - exposes `createOpenAIProvider(...)` convenience constructor
library;

import 'config.dart';
import 'provider.dart';
import 'defaults.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';
export 'audio.dart';
export 'images.dart';
export 'files.dart';
export 'models.dart';
export 'moderation.dart';
export 'assistants.dart';
export 'completion.dart';

// OpenAI Responses API modules
export 'responses.dart';
export 'responses_capability.dart';
export 'responses_message_converter.dart';

// Built-in tool helpers
export 'builtin_tools.dart';
export 'provider_tools.dart';
export 'web_search_context_size.dart';

// HTTP strategy (shared with OpenAI-compatible reuse)
export 'dio_strategy.dart';

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
