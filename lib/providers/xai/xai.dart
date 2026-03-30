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
///   ChatMessage.user('What are the latest developments in AI?')
/// ]);
/// ```
library;

import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';

/// Create an xAI provider with default settings
XAIProvider createXAIProvider({
  required String apiKey,
  String model = 'grok-3',
  String baseUrl = 'https://api.x.ai/v1/',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  SearchParameters? searchParameters,
  bool? liveSearch,
}) {
  final config = XAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    searchParameters: searchParameters,
    liveSearch: liveSearch,
  );

  return XAIProvider(config);
}

/// Create an xAI provider with search capabilities
@Deprecated(
  'createXAISearchProvider() is a legacy helper. '
  'Prefer createXAIProvider(...) for root-package compatibility or the stable AI.xai(...).chatModel(...) API with typed XAIGenerateTextOptions(search: ...).',
)
XAIProvider createXAISearchProvider({
  required String apiKey,
  String model = 'grok-3',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  String searchMode = 'auto',
  List<SearchSource>? sources,
  int? maxSearchResults,
  String? fromDate,
  String? toDate,
}) {
  final searchParams = SearchParameters(
    mode: searchMode,
    sources: sources ?? [const SearchSource(sourceType: 'web')],
    maxSearchResults: maxSearchResults,
    fromDate: fromDate,
    toDate: toDate,
  );

  final config = XAIConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    searchParameters: searchParams,
    liveSearch: true, // Explicitly enable live search
  );

  return XAIProvider(config);
}

/// Create an xAI provider with Live Search enabled
///
/// This is a convenience function that enables Live Search with default web search settings.
/// Live Search allows Grok models to access real-time information from the web.
///
/// Example:
/// ```dart
/// final provider = createXAILiveSearchProvider(
///   apiKey: 'your-api-key',
///   model: 'grok-3',
///   maxSearchResults: 5,
/// );
///
/// final response = await provider.chat([
///   ChatMessage.user('What are the latest developments in AI?')
/// ]);
/// ```
@Deprecated(
  'createXAILiveSearchProvider() is a legacy helper. '
  'Prefer createXAIProvider(...) for root-package compatibility or the stable AI.xai(...).chatModel(...) API with typed XAIGenerateTextOptions(search: ...).',
)
XAIProvider createXAILiveSearchProvider({
  required String apiKey,
  String model = 'grok-3',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  int? maxSearchResults,
  List<String>? excludedWebsites,
}) {
  final config = XAIConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    liveSearch: true,
    searchParameters: SearchParameters.webSearch(
      maxResults: maxSearchResults,
      excludedWebsites: excludedWebsites,
    ),
  );

  return XAIProvider(config);
}

/// Create an xAI provider for Grok Vision
XAIProvider createGrokVisionProvider({
  required String apiKey,
  String model = 'grok-vision-beta',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = XAIConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return XAIProvider(config);
}
