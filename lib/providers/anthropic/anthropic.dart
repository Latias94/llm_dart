/// Modular Anthropic Provider
///
/// This library provides a modular implementation of the Anthropic provider
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
/// import 'package:llm_dart/providers/anthropic/anthropic.dart';
///
/// final provider = AnthropicProvider(AnthropicConfig(
///   apiKey: 'your-api-key',
///   model: 'claude-sonnet-4-20250514',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'package:llm_dart_anthropic/llm_dart_anthropic.dart';
import '../../core/provider_defaults.dart';

export 'package:llm_dart_anthropic/llm_dart_anthropic.dart'
    show AnthropicConfig, AnthropicProvider;
export 'mcp_models.dart';

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
