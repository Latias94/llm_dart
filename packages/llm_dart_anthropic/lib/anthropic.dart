/// Anthropic provider package entrypoint.
library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart'
    show AnthropicConfig, anthropicBaseUrl, anthropicDefaultModel;

import 'provider.dart';

// Provider modules
export 'provider.dart';
//
// Advanced endpoint wrappers are opt-in:
// - `package:llm_dart_anthropic/files.dart`
// - `package:llm_dart_anthropic/models.dart`

/// Create an Anthropic provider with default configuration.
AnthropicProvider createAnthropicProvider({
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
  bool? reasoning,
  int? thinkingBudgetTokens,
  bool? interleavedThinking,
}) {
  final config = AnthropicConfig(
    apiKey: apiKey,
    model: model ?? anthropicDefaultModel,
    baseUrl: baseUrl ?? anthropicBaseUrl,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    stream: stream ?? false,
    topP: topP,
    topK: topK,
    reasoning: reasoning ?? false,
    thinkingBudgetTokens: thinkingBudgetTokens,
    interleavedThinking: interleavedThinking ?? false,
  );

  return AnthropicProvider(config);
}
