/// Modular xAI Provider.
library;

import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';
import 'src/xai_provider_v3.dart';

export 'config.dart';
export 'provider.dart';

export 'src/xai_provider_v3.dart' show XAIProviderV3, XAIProviderSettings;

/// Create an xAI provider (AI SDK v3 style).
XAIProviderV3 createXai({
  Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  SearchParameters? searchParameters,
  bool? liveSearch,
  XAIProvider Function(XAIConfig config, {OpenAIClient? client})?
      providerFactory,
  XAIProviderClientFactory? clientFactory,
}) {
  return XAIProviderV3(
    XAIProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      searchParameters: searchParameters,
      liveSearch: liveSearch,
      providerFactory: providerFactory,
      clientFactory: clientFactory,
    ),
  );
}

/// Alias for `createXai(...)` (upstream parity).
XAIProviderV3 xai({
  Object? apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
  SearchParameters? searchParameters,
  bool? liveSearch,
  XAIProvider Function(XAIConfig config, {OpenAIClient? client})?
      providerFactory,
  XAIProviderClientFactory? clientFactory,
}) =>
    createXai(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
      searchParameters: searchParameters,
      liveSearch: liveSearch,
      providerFactory: providerFactory,
      clientFactory: clientFactory,
    );

@Deprecated('Use createXai()/xai() (ProviderV3) instead.')
XAIProvider createXAIProvider({
  required String apiKey,
  String model = 'grok-3',
  String imageModel = 'grok-2-image',
  String videoModel = 'grok-imagine-video',
  String baseUrl = xaiBaseUrl,
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
