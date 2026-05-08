import '../../../core/config.dart';
import '../../../providers/openai/config.dart';
import '../config/legacy_config_extensions.dart';
import '../config/legacy_openai_options.dart';
import '../config/legacy_provider_options.dart';
import '../config/legacy_web_search_options.dart';
import 'community_provider_config_adapters.dart';

OpenAIConfig createLegacyOpenAIConfig(LLMConfig config) =>
    toCompatLegacyOpenAIConfig(config);

OpenAIConfig toCompatLegacyOpenAIConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.openai,
  );
  var model = config.model;
  final webSearchOptions = legacyWebSearchOptions(options);
  if (webSearchOptions.hasSearchIntent && !isCompatOpenAISearchModel(model)) {
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
  return createCompatOpenAIFamilyConfig(
    config: config,
    model: model,
    options: options,
    includeOpenAIHostedOptions: true,
  );
}

OpenAIConfig createCompatOpenAIFamilyConfig({
  required LLMConfig config,
  required String model,
  required LegacyProviderOptionView options,
  bool includeOpenAIHostedOptions = false,
}) {
  final familyOptions = legacyOpenAIFamilyOptions(options);
  final hostedOptions =
      includeOpenAIHostedOptions ? legacyOpenAIHostedOptions(options) : null;

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
    reasoningEffort: hostedOptions?.reasoningEffort,
    jsonSchema: familyOptions.jsonSchema,
    voice: hostedOptions?.voice,
    embeddingEncodingFormat: hostedOptions?.embeddingEncodingFormat,
    embeddingDimensions: hostedOptions?.embeddingDimensions,
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: familyOptions.useResponsesAPI,
    previousResponseId: familyOptions.previousResponseId,
    builtInTools: familyOptions.builtInTools,
    frequencyPenalty: familyOptions.frequencyPenalty,
    presencePenalty: familyOptions.presencePenalty,
    logitBias: familyOptions.logitBias,
    seed: familyOptions.seed,
    parallelToolCalls: familyOptions.parallelToolCalls,
    logprobs: familyOptions.logprobs,
    topLogprobs: familyOptions.topLogprobs,
    verbosity: familyOptions.verbosity,
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
