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

import '../../src/provider_defaults.dart';
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'provider.dart';
export 'builder.dart';

// Explicit residual public OpenAI compatibility surfaces
export 'responses.dart';
export 'responses_capability.dart';
export 'builtin_tools.dart';

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

/// Create an OpenAI provider for OpenRouter
@Deprecated(
  'createOpenRouterProvider() is a legacy preset helper. '
  'Prefer the stable AI.openRouter(...).chatModel(...) API. '
  'If you still need the old root-package OpenAIProvider surface temporarily, '
  'use createOpenAIProvider(...) with explicit OpenRouter baseUrl/model settings. '
  'This helper remains a compatibility alias and is not targeted for a profile-specific modern bridge.',
)
OpenAIProvider createOpenRouterProvider({
  required String apiKey,
  String model = ProviderDefaults.openRouterDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: ProviderDefaults.openRouterBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}

/// Create an OpenAI provider for Groq
@Deprecated(
  'createGroqProvider() is a legacy preset helper. '
  'Prefer the stable AI.groq(...).chatModel(...) API. '
  'If you still need the old root-package OpenAIProvider surface temporarily, '
  'use createOpenAIProvider(...) with explicit Groq baseUrl/model settings. '
  'This helper remains a compatibility alias and is not targeted for a profile-specific modern bridge.',
)
OpenAIProvider createGroqProvider({
  required String apiKey,
  String model = ProviderDefaults.groqDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: ProviderDefaults.groqBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}

/// Create an OpenAI provider for DeepSeek
@Deprecated(
  'createDeepSeekProvider() is a legacy preset helper. '
  'Prefer the stable AI.deepSeek(...).chatModel(...) API. '
  'If you still need the old root-package OpenAIProvider surface temporarily, '
  'use createOpenAIProvider(...) with explicit DeepSeek baseUrl/model settings. '
  'This helper remains a compatibility alias and is not targeted for a profile-specific modern bridge.',
)
OpenAIProvider createDeepSeekProvider({
  required String apiKey,
  String model = ProviderDefaults.deepseekDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: ProviderDefaults.deepseekBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}

/// Create an OpenAI provider for Azure OpenAI
@Deprecated(
  'createAzureOpenAIProvider() is a legacy preset helper. '
  'Prefer AI.openai(...).chatModel(...) for migrated OpenAI-compatible text usage, '
  'or use createOpenAIProvider(...) with explicit Azure endpoint-style baseUrl/model settings '
  'when you still need the old root-package OpenAIProvider surface. '
  'This helper remains a compatibility alias and is not targeted for a dedicated modern Azure bridge.',
)
OpenAIProvider createAzureOpenAIProvider({
  required String apiKey,
  required String endpoint,
  required String deploymentName,
  String apiVersion = '2024-02-15-preview',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: deploymentName,
    baseUrl: '$endpoint/openai/deployments/$deploymentName/',
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}

/// Create an OpenAI provider for GitHub Copilot
@Deprecated(
  'createCopilotProvider() is a legacy preset helper. '
  'Prefer AI.openai(...).chatModel(...) with explicit Copilot-compatible baseUrl/model settings, '
  'or use createOpenAIProvider(...) when you still need the old root-package OpenAIProvider surface. '
  'This helper remains a compatibility alias and is not targeted for a profile-specific modern bridge.',
)
OpenAIProvider createCopilotProvider({
  required String apiKey,
  String model = ProviderDefaults.githubCopilotDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: ProviderDefaults.githubCopilotBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}

/// Create an OpenAI provider for Together AI
@Deprecated(
  'createTogetherProvider() is a legacy preset helper. '
  'Prefer AI.openai(...).chatModel(...) with explicit Together-compatible baseUrl/model settings, '
  'or use createOpenAIProvider(...) when you still need the old root-package OpenAIProvider surface. '
  'This helper remains a compatibility alias and is not targeted for a profile-specific modern bridge.',
)
OpenAIProvider createTogetherProvider({
  required String apiKey,
  String model = ProviderDefaults.togetherAIDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: ProviderDefaults.togetherAIBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return OpenAIProvider(config);
}
