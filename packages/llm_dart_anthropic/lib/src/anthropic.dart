/// Modular Anthropic Provider
library;

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';

import 'provider.dart';

// Re-export compatible layer for convenience
export 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';

// Provider exports
export 'provider.dart';
export 'files.dart';
export 'models.dart';

/// Create an Anthropic provider with default configuration
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
    model: model ?? ProviderDefaults.anthropicDefaultModel,
    baseUrl: baseUrl ?? ProviderDefaults.anthropicBaseUrl,
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

/// Create an Anthropic provider for chat
AnthropicProvider createAnthropicChatProvider({
  required String apiKey,
  String model = 'claude-sonnet-4-20250514',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createAnthropicProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create an Anthropic provider for reasoning tasks
AnthropicProvider createAnthropicReasoningProvider({
  required String apiKey,
  String model = 'claude-sonnet-4-20250514',
  String? systemPrompt,
  int? thinkingBudgetTokens,
  bool interleavedThinking = false,
}) {
  return createAnthropicProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    reasoning: true,
    thinkingBudgetTokens: thinkingBudgetTokens,
    interleavedThinking: interleavedThinking,
  );
}
