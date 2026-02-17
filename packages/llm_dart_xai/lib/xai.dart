/// Modular xAI Provider.
library;

import 'config.dart';
import 'provider.dart';

export 'config.dart';
export 'provider.dart';

XAIProvider createXAIProvider({
  required String apiKey,
  String model = 'grok-3',
  String imageModel = 'grok-2-image',
  String videoModel = 'grok-imagine-video',
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
    imageModel: imageModel,
    videoModel: videoModel,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    searchParameters: searchParameters?.copyWith(),
    liveSearch: liveSearch,
  );

  return XAIProvider(config);
}
