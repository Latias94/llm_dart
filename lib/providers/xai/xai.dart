// The xAI provider facade is prompt-first and re-exports the
// dedicated `llm_dart_xai` subpackage.

/// Modular xAI Provider
///
/// This library provides a modular implementation of the xAI provider
/// following the same architecture pattern as the OpenAI provider.
///
/// **Key Features:**
/// - Grok models with real-time search capabilities
/// - Reasoning and thinking support
/// - Modular architecture for easy maintenance
/// - Support for structured outputs
/// - Search parameters for web and news sources
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/llm_dart.dart';
/// import 'package:llm_dart/providers/xai/xai.dart';
///
/// final provider = XAIProvider(XAIConfig(
///   apiKey: 'your-api-key',
///   model: 'grok-3',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
///
/// // Use search with Grok
/// final searchConfig = XAIConfig(
///   apiKey: 'your-api-key',
///   model: 'grok-3',
///   searchParameters: SearchParameters(
///     mode: 'auto',
///     sources: [SearchSource(sourceType: 'web')],
///   ),
/// );
/// final searchProvider = XAIProvider(searchConfig);
/// final searchResponse = await searchProvider.chat([
///   ModelMessage.userText('What are the latest developments in AI?')
/// ]);
/// ```
library;

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';

// Vercel AI-style facade
export 'package:llm_dart_xai/llm_dart_xai.dart'
    show
        XAIProviderSettings,
        XAI,
        XAITools,
        XAIProviderDefinedTools,
        createXAI,
        xai;
