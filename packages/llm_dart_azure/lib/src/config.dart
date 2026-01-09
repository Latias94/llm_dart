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
    required String apiKey,
    required String baseUrl,
    required String model,
    this.apiVersion = azureDefaultApiVersion,
    this.useDeploymentBasedUrls = false,
    this.useResponsesAPI = true,
    this.previousResponseId,
    this.builtInTools,
    Map<String, dynamic>? extraBody,
    Map<String, String>? extraHeaders,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    ReasoningEffort? reasoningEffort,
    StructuredOutputFormat? jsonSchema,
    String? voice,
    String? embeddingEncodingFormat,
    int? embeddingDimensions,
    List<String>? stopSequences,
    String? user,
    ServiceTier? serviceTier,
    LLMConfig? originalConfig,
  }) : super(
          providerId: azureProviderId,
          providerName: 'Azure OpenAI',
          apiKey: apiKey,
          baseUrl: baseUrl,
          model: model,
          extraBody: extraBody,
          extraHeaders: extraHeaders,
          maxTokens: maxTokens,
          temperature: temperature,
          systemPrompt: systemPrompt,
          timeout: timeout,
          topP: topP,
          topK: topK,
          tools: tools,
          toolChoice: toolChoice,
          reasoningEffort: reasoningEffort,
          jsonSchema: jsonSchema,
          voice: voice,
          embeddingEncodingFormat: embeddingEncodingFormat,
          embeddingDimensions: embeddingDimensions,
          stopSequences: stopSequences,
          user: user,
          serviceTier: serviceTier,
          originalConfig: originalConfig,
        );

  @override
  T? getProviderOption<T>(String key) {
    if (key == 'apiVersion') return apiVersion as T?;
    if (key == 'useDeploymentBasedUrls') return useDeploymentBasedUrls as T?;
    return super.getProviderOption<T>(key);
  }
}
