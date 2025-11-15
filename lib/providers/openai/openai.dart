/// Modular OpenAI Provider
///
/// This library provides a modular implementation of the OpenAI provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/openai/openai.dart';
///
/// final provider = ModularOpenAIProvider(ModularOpenAIConfig(
///   apiKey: 'your-api-key',
///   model: 'gpt-4',
/// ));
///
/// // Use any capability - same external API
/// final response = await provider.chat(messages);
/// final embeddings = await provider.embed(['text']);
/// final audio = await provider.speech('Hello world');
/// ```
library;

import '../../core/provider_defaults.dart';
import 'config.dart';
import 'provider.dart';

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
export 'responses.dart';
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

/// Create an OpenAI provider for Groq.
///
/// This legacy helper treats Groq as an OpenAI-compatible endpoint.
/// New code should prefer the dedicated Groq provider from
/// `package:llm_dart/providers/groq/groq.dart` or use
/// `ai().groq()` / `GroqProviderFactory` instead.
@Deprecated(
  'Use GroqProvider from package:llm_dart/providers/groq/groq.dart '
  'or ai().groq() instead of createGroqProvider on the OpenAI facade.',
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

/// Create an OpenAI provider for DeepSeek.
///
/// This legacy helper treats DeepSeek as an OpenAI-compatible endpoint.
/// New code should prefer the dedicated DeepSeek provider from
/// `package:llm_dart/providers/deepseek/deepseek.dart` or use
/// `ai().deepseek()` / `DeepSeekProviderFactory` instead.
@Deprecated(
  'Use DeepSeekProvider from package:llm_dart/providers/deepseek/deepseek.dart '
  'or ai().deepseek() instead of createDeepSeekProvider on the OpenAI facade.',
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
