/// Compatibility-first OpenAI provider barrel.
///
/// Keeps the legacy root OpenAI provider constructors, compatibility-facing
/// config types, the old builder DSL, and the raw OpenAI Responses residual
/// API surface.
///
/// New code should usually prefer:
///
/// - `package:llm_dart/openai.dart` for the modern provider-owned OpenAI
///   package surface
/// - `AI.openai(...).chatModel(...)` and the other stable model constructors
/// - `package:llm_dart/legacy.dart` if broad compatibility exports are needed
///
/// **Compatibility Usage:**
/// ```dart
/// import 'package:llm_dart/providers/openai/openai.dart';
///
/// final provider = createOpenAIProvider(
///   apiKey: 'your-api-key',
///   model: 'gpt-4o',
/// );
///
/// // Use the old root OpenAI provider surface when migration code still needs it
/// final response = await provider.chat(messages);
/// ```
library;

import '../../src/config/provider_defaults.dart';
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'provider.dart';
export 'builder.dart';

// Explicit residual public OpenAI compatibility surfaces
export 'responses.dart';
export 'responses_capability.dart';
export 'responses_models.dart';
export 'assistants.dart';
export 'builtin_tools.dart';
export 'audio.dart' show AudioTranslationRequest;

/// Create an OpenAI provider with default settings
OpenAIProvider createOpenAIProvider({
  required String apiKey,
  String model = ProviderDefaults.openaiDefaultModel,
  String baseUrl = ProviderDefaults.openaiBaseUrl,
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
