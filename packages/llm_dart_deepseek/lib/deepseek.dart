/// DeepSeek Provider (OpenAI-compatible)
///
/// DeepSeek's HTTP API follows an OpenAI-compatible shape. This package keeps a
/// thin provider wrapper and delegates protocol behavior to
/// `llm_dart_openai_compatible` so we don't duplicate request/stream parsing
/// logic across compatible providers.
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart_deepseek/deepseek.dart';
///
/// final provider = DeepSeekProvider(DeepSeekConfig(
///   apiKey: 'your-api-key',
///   model: 'deepseek-chat',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'provider.dart';
// Advanced endpoint wrappers are opt-in:
// - `package:llm_dart_deepseek/models.dart`

/// Create a DeepSeek provider with default configuration
DeepSeekProvider createDeepSeekProvider({
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
}) {
  final config = DeepSeekConfig(
    apiKey: apiKey,
    model: model ?? 'deepseek-chat',
    baseUrl: baseUrl ?? 'https://api.deepseek.com/v1/',
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
  );

  return DeepSeekProvider(config);
}

/// Create a DeepSeek provider for chat
DeepSeekProvider createDeepSeekChatProvider({
  required String apiKey,
  String model = 'deepseek-chat',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createDeepSeekProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a DeepSeek provider for reasoning tasks
/// Uses the deepseek-reasoner model which supports reasoning/thinking
DeepSeekProvider createDeepSeekReasoningProvider({
  required String apiKey,
  String model = 'deepseek-reasoner',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createDeepSeekProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}
