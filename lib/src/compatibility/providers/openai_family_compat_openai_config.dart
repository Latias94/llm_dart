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
      options.get<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig =
      options.get<WebSearchConfig>(LegacyExtensionKeys.webSearchConfig);
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
        options.get<dynamic>(LegacyExtensionKeys.reasoningEffort),
      ),
    ),
    jsonSchema: options.get<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    voice: options.get<String>(LegacyExtensionKeys.voice),
    embeddingEncodingFormat: options.get<String>(
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: options.get<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI:
        options.get<bool>(LegacyExtensionKeys.useResponsesApi) ?? false,
    previousResponseId: options.get<String>(
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: options.get<List<OpenAIBuiltInTool>>(
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: options.get<double>(
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: options.get<double>(
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: options.get<Map<String, double>>(
      LegacyExtensionKeys.logitBias,
    ),
    seed: options.get<int>(LegacyExtensionKeys.seed),
    parallelToolCalls: options.get<bool>(
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: options.get<bool>(LegacyExtensionKeys.logprobs),
    topLogprobs: options.get<int>(LegacyExtensionKeys.topLogprobs),
    verbosity: options.get<String>(LegacyExtensionKeys.verbosity),
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
