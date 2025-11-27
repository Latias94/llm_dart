/// Modular Groq Provider
///
/// This library provides a modular implementation of the Groq provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
/// - Speed Optimized: Groq is known for fast inference
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/groq/groq.dart';
///
/// final provider = GroqProvider(GroqConfig(
///   apiKey: 'your-api-key',
///   model: 'llama-3.3-70b-versatile',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';

/// Create a Groq provider with default configuration
GroqProvider createGroqProvider({
  required String apiKey,
  String? model,
  String? baseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  bool? stream,
  double? topP,
  int? topK,
  List<Tool>? tools,
  ToolChoice? toolChoice,
}) {
  final config = GroqConfig(
    apiKey: apiKey,
    model: model ?? 'llama-3.3-70b-versatile',
    baseUrl: baseUrl ?? 'https://api.groq.com/openai/v1/',
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
    tools: tools,
    toolChoice: toolChoice,
  );

  return GroqProvider(config);
}

/// Create a Groq provider for chat
GroqProvider createGroqChatProvider({
  required String apiKey,
  String model = 'llama-3.3-70b-versatile',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Groq provider for fast inference
GroqProvider createGroqFastProvider({
  required String apiKey,
  String model = 'llama-3.1-8b-instant',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Groq provider for vision tasks
GroqProvider createGroqVisionProvider({
  required String apiKey,
  String model = 'llava-v1.5-7b-4096-preview',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Groq provider for code generation
GroqProvider createGroqCodeProvider({
  required String apiKey,
  String model = 'llama-3.1-70b-versatile',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGroqProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature ?? 0.1, // Lower temperature for code
    maxTokens: maxTokens,
  );
}
