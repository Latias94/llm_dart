import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/config.dart';
import '../config/legacy_config_extensions.dart';
import '../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';
import 'compat_provider_support.dart';

OpenAIConfig createLegacyOpenAIConfig(LLMConfig config) =>
    toCompatLegacyOpenAIConfig(config);

OpenAIConfig toCompatLegacyOpenAIConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled = getLegacyProviderOption<bool>(
        config,
        LegacyProviderOptionNamespaces.openai,
        LegacyExtensionKeys.webSearchEnabled,
      ) ==
      true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openai,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !isCompatOpenAISearchModel(model)) {
    model = compatOpenAISearchModelFor(model);
  }

  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    transportClient: config.legacyTransportClient,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    reasoningEffort: ReasoningEffort.fromString(
      compatStringValue(
        getLegacyProviderOption<dynamic>(
          config,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.reasoningEffort,
        ),
      ),
    ),
    jsonSchema: getLegacyProviderOption<StructuredOutputFormat>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.jsonSchema,
    ),
    voice: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.voice,
    ),
    embeddingEncodingFormat: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.embeddingDimensions,
    ),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false,
    previousResponseId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: getLegacyProviderOption<Map<String, double>>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.logitBias,
    ),
    seed: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.seed,
    ),
    parallelToolCalls: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.logprobs,
    ),
    topLogprobs: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.topLogprobs,
    ),
    verbosity: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.verbosity,
    ),
  );
}

OpenAIConfig createLegacyOpenAICompatibleConfig(LLMConfig config) {
  return OpenAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    transportClient: config.legacyTransportClient,
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    reasoningEffort: ReasoningEffort.fromString(
      compatStringValue(
        getLegacyProviderOption<dynamic>(
          config,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.reasoningEffort,
        ),
      ),
    ),
    jsonSchema: getLegacyProviderOption<StructuredOutputFormat>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.jsonSchema,
    ),
    voice: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.voice,
    ),
    embeddingEncodingFormat: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.embeddingDimensions,
    ),
    useResponsesAPI: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false,
    previousResponseId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: getLegacyProviderOption<Map<String, double>>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.logitBias,
    ),
    seed: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.seed,
    ),
    parallelToolCalls: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.logprobs,
    ),
    topLogprobs: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.topLogprobs,
    ),
    verbosity: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.verbosity,
    ),
  );
}

bool isCompatOpenAISearchModel(String model) {
  return model.contains('search-preview') || model.contains('search');
}

String compatOpenAISearchModelFor(String model) {
  if (model.startsWith('gpt-4o-mini')) {
    return 'gpt-4o-mini-search-preview';
  }

  if (model.startsWith('gpt-4o')) {
    return 'gpt-4o-search-preview';
  }

  return 'gpt-4o-search-preview';
}
