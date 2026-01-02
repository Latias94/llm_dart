/// Modular xAI Provider.
library;

import 'config.dart';
import 'provider.dart';

export 'config.dart';
export 'provider.dart';

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
