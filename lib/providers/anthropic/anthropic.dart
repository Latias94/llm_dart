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

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'defaults.dart';
export 'client.dart';
export 'provider.dart';
export 'builder.dart';

// Capability modules
export 'chat.dart';
export 'files.dart';

// MCP models
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
    model: model ?? AnthropicDefaults.defaultModel,
    baseUrl: baseUrl ?? AnthropicDefaults.baseUrl,
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
