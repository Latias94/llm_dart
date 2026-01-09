import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/builtin_tools.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../defaults.dart';
import '../config.dart';
import '../provider.dart';

/// Register the Azure OpenAI provider in the global [LLMProviderRegistry].
void registerAzure({bool replace = false}) {
  if (!replace && LLMProviderRegistry.isRegistered(azureProviderId)) return;
  final factory = AzureOpenAIProviderFactory();
  if (replace) {
    LLMProviderRegistry.registerOrReplace(factory);
    return;
  }
  LLMProviderRegistry.register(factory);
}

/// Factory for creating Azure OpenAI provider instances.
class AzureOpenAIProviderFactory
    extends OpenAICompatibleBaseFactory<ChatCapability> {
  @override
  String get providerId => azureProviderId;

  @override
  String get displayName => 'Azure OpenAI';

  @override
  String get description => 'Azure OpenAI models (OpenAI-compatible).';

  @override
  Set<LLMCapability> get supportedCapabilities => {
        LLMCapability.chat,
        LLMCapability.streaming,
        LLMCapability.embedding,
        LLMCapability.toolCalling,
        LLMCapability.reasoning,
        LLMCapability.vision,
        LLMCapability.imageGeneration,
        LLMCapability.textToSpeech,
        LLMCapability.speechToText,
        LLMCapability.audioTranslation,
        LLMCapability.openaiResponses,
      };

  @override
  ChatCapability create(LLMConfig config) {
    return createProviderSafely<AzureOpenAIConfig>(
      config,
      () => _transformConfig(config),
      (azureConfig) => AzureOpenAIProvider(azureConfig),
    );
  }

  @override
  Map<String, dynamic> getProviderDefaults() {
    final resourceName = Platform.environment['AZURE_RESOURCE_NAME'];
    final baseUrl = (resourceName != null && resourceName.trim().isNotEmpty)
        ? 'https://${resourceName.trim()}.openai.azure.com/openai'
        : 'https://example.openai.azure.com/openai';

    return {
      'baseUrl': baseUrl,
      'model': 'gpt-4o', // deployment name
    };
  }

  AzureOpenAIConfig _transformConfig(LLMConfig config) {
    final providerOptions = config.providerOptions;

    final baseUrlPrefix = config.baseUrl.trim().replaceAll(RegExp(r'/*$'), '');
    final apiVersion = readProviderOption<String>(
          providerOptions,
          providerId,
          'apiVersion',
        ) ??
        azureDefaultApiVersion;
    final useDeploymentBasedUrls = readProviderOption<bool>(
          providerOptions,
          providerId,
          'useDeploymentBasedUrls',
        ) ??
        false;

    final apiRoot = useDeploymentBasedUrls
        ? '$baseUrlPrefix/deployments/${Uri.encodeComponent(config.model)}'
        : '$baseUrlPrefix/v1';

    final extraBody =
        readProviderOptionMap(providerOptions, providerId, 'extraBody');
    final extraHeadersRaw =
        readProviderOptionMap(providerOptions, providerId, 'extraHeaders');
    final extraHeaders = _parseStringMap(extraHeadersRaw);

    final builtInTools = _parseBuiltInTools(config.providerTools);

    return AzureOpenAIConfig(
      apiKey: config.apiKey ?? '',
      baseUrl: '$apiRoot/',
      model: config.model,
      apiVersion: apiVersion,
      useDeploymentBasedUrls: useDeploymentBasedUrls,
      extraBody: extraBody,
      extraHeaders: extraHeaders,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      stopSequences: config.stopSequences,
      user: config.user,
      serviceTier: config.serviceTier,
      builtInTools: builtInTools,
      useResponsesAPI: true,
      originalConfig: config,
    );
  }

  Map<String, String>? _parseStringMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final result = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is String) {
        result[key] = value;
      } else if (value != null) {
        result[key] = value.toString();
      }
    }
    return result.isEmpty ? null : result;
  }

  List<OpenAIBuiltInTool>? _parseBuiltInTools(List<ProviderTool>? tools) {
    if (tools == null || tools.isEmpty) return null;

    final built = <OpenAIBuiltInTool>[];

    for (final tool in tools) {
      switch (tool.id) {
        case 'openai.web_search_preview':
          built.add(OpenAIBuiltInTools.webSearch());
          break;
        case 'openai.web_search':
          built.add(OpenAIBuiltInTools.webSearchFull());
          break;
        case 'openai.file_search':
          built.add(OpenAIBuiltInTools.fileSearch());
          break;
        case 'openai.code_interpreter':
          built.add(OpenAIBuiltInTools.codeInterpreter());
          break;
        case 'openai.image_generation':
          built.add(OpenAIBuiltInTools.imageGeneration());
          break;
        default:
          break;
      }
    }

    return built.isEmpty ? null : built;
  }
}
