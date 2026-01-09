/// Azure OpenAI provider package entrypoint.
///
/// Mirrors the "provider package" shape used by other `llm_dart_*` providers.
library;

import 'config.dart';
import 'provider.dart';
import 'defaults.dart';

export 'config.dart';
export 'provider.dart';

/// Create an Azure OpenAI provider with default settings.
AzureOpenAIProvider createAzureProvider({
  required String apiKey,
  required String model,
  required String baseUrl,
  String apiVersion = azureDefaultApiVersion,
  bool useDeploymentBasedUrls = false,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = AzureOpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    apiVersion: apiVersion,
    useDeploymentBasedUrls: useDeploymentBasedUrls,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    useResponsesAPI: true,
  );

  return AzureOpenAIProvider(config);
}
