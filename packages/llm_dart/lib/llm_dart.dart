/// LLM Dart Library - A modular Dart library for AI provider interactions
///
/// This library provides a unified interface for interacting with different
/// AI providers, starting with OpenAI. It's designed to be modular and
/// extensible
library;

// Core exports (standard surface + shared models)
export 'package:llm_dart_core/llm_dart_core.dart';

// Task APIs (Vercel-style)
export 'package:llm_dart_ai/llm_dart_ai.dart';

// Builder exports
export 'package:llm_dart_builder/llm_dart_builder.dart';

// Provider exports (all-in-one umbrella)
export 'package:llm_dart_azure/llm_dart_azure.dart';
export 'package:llm_dart_openai/llm_dart_openai.dart';
export 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart'
    hide
        openaiCompatibleFallbackModel,
        openaiStyleDefaultTTSModel,
        openaiStyleDefaultSTTModel,
        openaiStyleDefaultVoice,
        openaiStyleSupportedVoices,
        openaiStyleSupportedTTSFormats,
        openaiStyleSupportedSTTFormats,
        openaiStyleSupportedImageSizes,
        openaiStyleSupportedImageFormats;
export 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
export 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
export 'package:llm_dart_google/llm_dart_google.dart';
export 'package:llm_dart_google_vertex/llm_dart_google_vertex.dart';
export 'package:llm_dart_deepseek/llm_dart_deepseek.dart';
export 'package:llm_dart_ollama/llm_dart_ollama.dart';
export 'package:llm_dart_xai/llm_dart_xai.dart';
export 'package:llm_dart_groq/llm_dart_groq.dart';
export 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart';
export 'package:llm_dart_minimax/llm_dart_minimax.dart';

// Umbrella-only builder conveniences (do not live in provider subpackages)
export 'src/anthropic_builder.dart';
export 'src/builtin_llm_builder_extensions.dart';
export 'src/openai_builder.dart';
export 'src/openrouter_builder.dart';
export 'src/google_llm_builder.dart';
export 'src/ollama_builder.dart';
export 'src/elevenlabs_builder.dart';

// Convenience functions for creating providers
import 'builtins/builtin_provider_registry.dart';
import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Create a new LLM builder instance
///
/// This is the main entry point for creating AI providers.
///
/// Example:
/// ```dart
/// final provider = await ai()
///     .provider('openai')
///     .apiKey('your-key')
///     .model('gpt-4o')
///     .build();
/// ```
LLMBuilder ai() {
  BuiltinProviderRegistry.ensureRegistered();
  return LLMBuilder();
}

/// Create a provider with the given configuration
///
/// Convenience function for quickly creating providers with common settings.
///
/// Example:
/// ```dart
/// final provider = await createProvider(
///   providerId: 'openai',
///   apiKey: 'your-key',
///   model: 'gpt-4',
///   providerOptions: {
///     'frequencyPenalty': 0.3,
///   },
/// );
/// ```
Future<ChatCapability> createProvider({
  required String providerId,
  required String apiKey,
  required String model,
  String? baseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  Duration? timeout,
  double? topP,
  int? topK,
  Map<String, dynamic>? providerOptions,
}) async {
  BuiltinProviderRegistry.ensureRegistered();
  var builder = LLMBuilder().provider(providerId).apiKey(apiKey).model(model);

  if (baseUrl != null) builder = builder.baseUrl(baseUrl);
  if (temperature != null) builder = builder.temperature(temperature);
  if (maxTokens != null) builder = builder.maxTokens(maxTokens);
  if (systemPrompt != null) builder = builder.systemPrompt(systemPrompt);
  if (timeout != null) builder = builder.timeout(timeout);
  if (topP != null) builder = builder.topP(topP);
  if (topK != null) builder = builder.topK(topK);

  // Add providerOptions if provided
  if (providerOptions != null) {
    builder = builder.providerOptions(providerId, providerOptions);
  }

  return await builder.build();
}
