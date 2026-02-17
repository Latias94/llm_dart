import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/openai_compatible_config.dart';
import 'package:llm_dart_openai_compatible/openai_responses_config.dart';
import 'package:llm_dart_openai_compatible/builtin_tools.dart';

import '../defaults.dart';

/// Azure OpenAI provider configuration.
///
/// Azure OpenAI is OpenAI-compatible, but uses:
/// - `api-key` header authentication (handled by the OpenAI-compatible dio strategy)
/// - `api-version` query parameter (configured via [apiVersion])
/// - a different URL prefix: `https://{resource}.openai.azure.com/openai`
class AzureOpenAIConfig extends OpenAICompatibleConfig
    implements OpenAIResponsesConfig {
  /// Azure OpenAI `api-version` query parameter.
  final String apiVersion;

  /// Whether to use deployment-based URLs:
  /// `{baseUrl}/deployments/{deployment}{path}?api-version={apiVersion}`
  ///
  /// When false, uses the v1 format:
  /// `{baseUrl}/v1{path}?api-version={apiVersion}`
  final bool useDeploymentBasedUrls;

  /// Whether to use the OpenAI Responses API module for chat operations.
  final bool useResponsesAPI;

  @override
  final String? previousResponseId;

  @override
  final List<OpenAIBuiltInTool>? builtInTools;

  const AzureOpenAIConfig({
    String providerId = azureProviderId,
    String providerName = 'Azure OpenAI',
    required super.apiKey,
    required super.baseUrl,
    required super.model,
    this.apiVersion = azureDefaultApiVersion,
    this.useDeploymentBasedUrls = false,
    this.useResponsesAPI = true,
    this.previousResponseId,
    this.builtInTools,
    super.extraBody,
    super.extraHeaders,
    super.maxTokens,
    super.temperature,
    super.systemPrompt,
    super.timeout,
    super.topP,
    super.topK,
    super.tools,
    super.toolChoice,
    super.reasoningEffort,
    super.jsonSchema,
    super.voice,
    super.embeddingEncodingFormat,
    super.embeddingDimensions,
    super.stopSequences,
    super.user,
    super.serviceTier,
    super.originalConfig,
  }) : super(
          providerId: providerId,
          providerName: providerName,
        );

  @override
  T? getProviderOption<T>(String key) {
    if (key == 'apiVersion') return apiVersion as T?;
    if (key == 'useDeploymentBasedUrls') return useDeploymentBasedUrls as T?;
    final direct = super.getProviderOption<T>(key);
    if (direct != null) return direct;

    // For namespaced variants (e.g. "azure.chat"), fall back to the base
    // Azure provider options to keep escape hatches ergonomic.
    final original = originalConfig;
    if (original != null && providerId == azureChatProviderId) {
      return readProviderOption<T>(original.providerOptions, azureProviderId, key);
    }

    return null;
  }
}
