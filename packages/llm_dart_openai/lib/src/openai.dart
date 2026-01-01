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
/// import 'package:llm_dart_openai/llm_dart_openai.dart';
///
/// final provider = ModularOpenAIProvider(ModularOpenAIConfig(
///   apiKey: 'your-api-key',
///   model: 'gpt-4',
/// ));
///
/// // Use any capability - same external API
/// final response = await provider.chat(messages);
/// final embeddings = await provider.embed(['text']);
/// final tts = await provider.textToSpeech(const TTSRequest(text: 'Hello world'));
/// ```
library;

import 'config.dart';
import 'provider.dart';
import '../defaults.dart';

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
export 'responses_capability.dart';
export 'responses_message_converter.dart';
export 'builtin_tools.dart';
export 'provider_tools.dart';
export 'web_search_context_size.dart';

/// Create an OpenAI provider with default settings
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
