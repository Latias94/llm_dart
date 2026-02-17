import 'dart:io';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/builtin_tools.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../defaults.dart';
import '../config.dart';
import '../provider.dart';

/// Register the Azure OpenAI provider in the global [LLMProviderRegistry].
void registerAzure({bool replace = false}) {
  final responsesRegistered = LLMProviderRegistry.isRegistered(azureProviderId);
  final chatRegistered = LLMProviderRegistry.isRegistered(azureChatProviderId);

  if (!replace && responsesRegistered && chatRegistered) return;

  final responsesFactory = AzureOpenAIProviderFactory();
  final chatFactory = AzureOpenAIChatProviderFactory();

  if (replace) {
    LLMProviderRegistry.registerOrReplace(responsesFactory);
    LLMProviderRegistry.registerOrReplace(chatFactory);
    return;
  }

  if (!responsesRegistered) {
    LLMProviderRegistry.register(responsesFactory);
  }
  if (!chatRegistered) {
    LLMProviderRegistry.register(chatFactory);
  }
}

/// Factory for creating Azure OpenAI provider instances.
class AzureOpenAIProviderFactory
    extends OpenAICompatibleBaseFactory<ChatCapability> {
  @override
  String get providerId => azureProviderId;

  @override
  String get displayName => 'Azure OpenAI';

  @override
  String get description =>
      'Azure OpenAI models via the Responses API (default).';

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
    final fallbackProviderId =
        providerId == azureChatProviderId ? azureProviderId : null;

    if (readProviderOption<dynamic>(
          providerOptions,
          providerId,
          'useResponsesAPI',
          fallbackProviderId: fallbackProviderId,
        ) !=
        null) {
      throw InvalidRequestError(
        '"useResponsesAPI" has been removed. Use providerId "$azureProviderId" '
        '(Responses) or "$azureChatProviderId" (Chat Completions) instead.',
      );
    }

    final baseUrlPrefix = config.baseUrl.trim().replaceAll(RegExp(r'/*$'), '');
    final apiVersion = readProviderOption<String>(
          providerOptions,
          providerId,
          'apiVersion',
          fallbackProviderId: fallbackProviderId,
        ) ??
        azureDefaultApiVersion;
    final useResponsesAPI = providerId == azureProviderId;
    final useDeploymentBasedUrls = readProviderOption<bool>(
          providerOptions,
          providerId,
          'useDeploymentBasedUrls',
          fallbackProviderId: fallbackProviderId,
        ) ??
        false;

    final apiRoot = useDeploymentBasedUrls
        ? '$baseUrlPrefix/deployments/${Uri.encodeComponent(config.model)}'
        : '$baseUrlPrefix/v1';

    final extraBody = readProviderOptionMap(
      providerOptions,
      providerId,
      'extraBody',
      fallbackProviderId: fallbackProviderId,
    );
    final extraHeadersRaw = readProviderOptionMap(
      providerOptions,
      providerId,
      'extraHeaders',
      fallbackProviderId: fallbackProviderId,
    );
    final extraHeaders = _parseStringMap(extraHeadersRaw);

    final builtInTools = _parseBuiltInTools(config.providerTools);

    if (!useResponsesAPI) {
      if (config.providerTools != null && config.providerTools!.isNotEmpty) {
        throw InvalidRequestError(
          'providerTools are only supported with the Azure/OpenAI Responses API. '
          'Use providerId "$azureProviderId".',
        );
      }
      if (builtInTools != null && builtInTools.isNotEmpty) {
        throw InvalidRequestError(
          'Azure provider-native tools are only supported with the Responses API. '
          'Use providerId "$azureProviderId".',
        );
      }
    }

    return AzureOpenAIConfig(
      providerId: providerId,
      providerName: providerId == azureChatProviderId
          ? 'Azure OpenAI (Chat)'
          : 'Azure OpenAI',
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
      builtInTools: useResponsesAPI ? builtInTools : null,
      useResponsesAPI: useResponsesAPI,
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
        case 'azure.web_search_preview':
          built.add(OpenAIBuiltInTools.webSearch());
          break;
        case 'azure.web_search':
          built.add(OpenAIBuiltInTools.webSearchFull());
          break;
        case 'azure.file_search':
          built.add(OpenAIBuiltInTools.fileSearch());
          break;
        case 'azure.code_interpreter':
          built.add(OpenAIBuiltInTools.codeInterpreter());
          break;
        case 'azure.image_generation':
          built.add(OpenAIBuiltInTools.imageGeneration());
          break;
        default:
          break;
      }
    }

    return built.isEmpty ? null : built;
  }
}

/// Factory for creating Azure OpenAI Chat Completions provider instances.
class AzureOpenAIChatProviderFactory extends AzureOpenAIProviderFactory {
  @override
  String get providerId => azureChatProviderId;

  @override
  String get displayName => 'Azure OpenAI (Chat Completions)';

  @override
  String get description =>
      'Azure OpenAI models via Chat Completions (explicit).';

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
      };
}
