/// Modular xAI Provider.
library;

import 'package:llm_dart_core/core/config.dart';

import 'config.dart';
import 'provider.dart';
import 'responses_provider.dart';

export 'config.dart';
export 'provider.dart';
export 'responses.dart';
export 'responses_provider.dart';

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
    liveSearch: true,
  );

  return XAIProvider(config);
}

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

XAIResponsesProvider createXAIResponsesProvider({
  required String apiKey,
  String model = 'grok-4-fast',
  String baseUrl = 'https://api.x.ai/v1/',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  bool? store,
  String? previousResponseId,
}) {
  final llmConfig = LLMConfig(
    apiKey: apiKey,
    baseUrl: baseUrl,
    model: model,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    providerOptions: {
      'xai.responses': {
        if (store != null) 'store': store,
        if (previousResponseId != null)
          'previousResponseId': previousResponseId,
      },
    },
  );

  return XAIResponsesProvider(llmConfig);
}
