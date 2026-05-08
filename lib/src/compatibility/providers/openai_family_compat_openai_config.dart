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
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openai,
  );
  var model = config.model;
  final webSearchEnabled =
      options.getWithFlatFallback<bool>(LegacyExtensionKeys.webSearchEnabled) ==
          true;
  final webSearchConfig = options.getWithFlatFallback<WebSearchConfig>(
      LegacyExtensionKeys.webSearchConfig);
  if ((webSearchEnabled || webSearchConfig != null) &&
      !isCompatOpenAISearchModel(model)) {
    model = compatOpenAISearchModelFor(model);
  }

  return _createCompatOpenAIConfig(
    config: config,
    model: model,
    options: options,
  );
}

OpenAIConfig createLegacyOpenAICompatibleConfig(LLMConfig config) {
  return _createCompatOpenAIConfig(
    config: config,
    model: config.model,
    options: legacyProviderOptionView(
      config,
      LegacyProviderOptionNamespaces.openai,
    ),
  );
}

OpenAIConfig _createCompatOpenAIConfig({
  required LLMConfig config,
  required String model,
  required LegacyProviderOptionView options,
}) {
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
        options
            .getWithFlatFallback<dynamic>(LegacyExtensionKeys.reasoningEffort),
      ),
    ),
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    voice: options.getWithFlatFallback<String>(LegacyExtensionKeys.voice),
    embeddingEncodingFormat: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: options
            .getWithFlatFallback<bool>(LegacyExtensionKeys.useResponsesApi) ??
        false,
    previousResponseId: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: options.getWithFlatFallback<List<OpenAIBuiltInTool>>(
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: options.getWithFlatFallback<double>(
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: options.getWithFlatFallback<Map<String, double>>(
      LegacyExtensionKeys.logitBias,
    ),
    seed: options.getWithFlatFallback<int>(LegacyExtensionKeys.seed),
    parallelToolCalls: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: options.getWithFlatFallback<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs:
        options.getWithFlatFallback<int>(LegacyExtensionKeys.topLogprobs),
    verbosity:
        options.getWithFlatFallback<String>(LegacyExtensionKeys.verbosity),
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
