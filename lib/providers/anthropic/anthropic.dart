// The Anthropic provider facade is prompt-first and re-exports the
// dedicated `llm_dart_anthropic` subpackage.

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

// Re-export core Anthropic types from the dedicated subpackage so that
// existing imports continue to work:
//
//   import 'package:llm_dart/providers/anthropic/anthropic.dart';
//
export 'package:llm_dart_anthropic/llm_dart_anthropic.dart'
    show
        AnthropicConfig,
        AnthropicProvider,
        AnthropicProviderSettings,
        Anthropic,
        AnthropicTools,
        createAnthropic,
        anthropic;

export 'mcp_models.dart';
