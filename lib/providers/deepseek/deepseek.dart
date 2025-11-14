/// DeepSeek Provider facade for the main `llm_dart` package.
///
/// This library now re-exports the DeepSeek provider implementation
/// from the `llm_dart_deepseek` subpackage, while keeping the original
/// import path stable for backwards compatibility.
library;

import 'package:llm_dart_deepseek/llm_dart_deepseek.dart';

export 'package:llm_dart_deepseek/llm_dart_deepseek.dart'
    show DeepSeekConfig, DeepSeekProvider;

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
