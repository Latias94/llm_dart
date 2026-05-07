import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;

import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/config.dart';
import '../../../providers/xai/config.dart';
import '../../config/legacy_config_extensions.dart';
import '../../config/legacy_provider_options.dart';
import 'community_provider_config_adapters.dart';
import 'compat_provider_support.dart';

OpenAIConfig createLegacyOpenAIConfig(LLMConfig config) =>
    toCompatLegacyOpenAIConfig(config);

OpenAIConfig toCompatLegacyOpenAIConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled =
      config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
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
      compatStringValue(config.extensions['reasoningEffort']),
    ),
    jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
    voice: config.getExtension<String>('voice'),
    embeddingEncodingFormat:
        config.getExtension<String>('embeddingEncodingFormat'),
    embeddingDimensions: config.getExtension<int>('embeddingDimensions'),
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

OpenAIConfig toCompatLegacyOpenRouterConfig(LLMConfig config) {
  var model = config.model;
  final webSearchEnabled =
      config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openrouter,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !model.endsWith(':online')) {
    model = '$model:online';
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
    jsonSchema: config.getExtension<StructuredOutputFormat>('jsonSchema'),
    stopSequences: config.stopSequences,
    user: config.user,
    serviceTier: config.serviceTier,
    useResponsesAPI: getLegacyProviderOption<bool>(
          config,
          LegacyProviderOptionNamespaces.openrouter,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false,
    previousResponseId: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.previousResponseId,
    ),
    builtInTools: getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.builtInTools,
    ),
    frequencyPenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.frequencyPenalty,
    ),
    presencePenalty: getLegacyProviderOption<double>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.presencePenalty,
    ),
    logitBias: getLegacyProviderOption<Map<String, double>>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.logitBias,
    ),
    seed: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.seed,
    ),
    parallelToolCalls: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.parallelToolCalls,
    ),
    logprobs: getLegacyProviderOption<bool>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.logprobs,
    ),
    topLogprobs: getLegacyProviderOption<int>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.topLogprobs,
    ),
    verbosity: getLegacyProviderOption<String>(
      config,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.verbosity,
    ),
  );
}

core.ProviderModelOptions buildCompatOpenRouterModelSettings(
  LLMConfig config,
) {
  final webSearchEnabled =
      config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true;
  final webSearchConfig = getLegacyProviderOption<WebSearchConfig>(
    config,
    LegacyProviderOptionNamespaces.openrouter,
    LegacyExtensionKeys.webSearchConfig,
  );
  if ((webSearchEnabled || webSearchConfig != null) &&
      !config.model.endsWith(':online')) {
    return const modern_openai.OpenRouterChatModelSettings(
      search: modern_openai.OpenRouterSearchOptions.onlineModel(),
    );
  }

  return const modern_openai.OpenAIChatModelSettings();
}

modern_openai.XAILiveSearchOptions? buildCompatXAILiveSearchOptions(
  XAIConfig config,
) {
  final searchParameters = normalizeCompatXAISearchParameters(config);
  if (searchParameters == null) {
    return null;
  }

  final mode = mapCompatXAISearchMode(searchParameters.mode);
  final sources = mapCompatXAISearchSources(searchParameters.sources);
  final fromDate = parseCompatUtcDate(searchParameters.fromDate);
  final toDate = parseCompatUtcDate(searchParameters.toDate);
  final maxSearchResults = searchParameters.maxSearchResults;

  if (mode == null ||
      sources == null ||
      (searchParameters.fromDate != null && fromDate == null) ||
      (searchParameters.toDate != null && toDate == null) ||
      (maxSearchResults != null &&
          (maxSearchResults < 1 || maxSearchResults > 50)) ||
      (fromDate != null && toDate != null && toDate.isBefore(fromDate))) {
    return null;
  }

  return modern_openai.XAILiveSearchOptions(
    mode: mode,
    fromDate: fromDate,
    toDate: toDate,
    maxSearchResults: maxSearchResults,
    sources: sources,
  );
}

SearchParameters? normalizeCompatXAISearchParameters(XAIConfig config) {
  final searchParameters = config.searchParameters;
  if (searchParameters == null) {
    return config.liveSearch == true ? SearchParameters.webSearch() : null;
  }

  final sources = searchParameters.sources?.isNotEmpty == true
      ? searchParameters.sources
      : [const SearchSource(sourceType: 'web')];

  return SearchParameters(
    mode: searchParameters.mode ?? 'auto',
    sources: sources,
    maxSearchResults: searchParameters.maxSearchResults,
    fromDate: searchParameters.fromDate,
    toDate: searchParameters.toDate,
  );
}

modern_openai.XAISearchMode? mapCompatXAISearchMode(String? mode) {
  return switch (mode) {
    null || 'auto' => modern_openai.XAISearchMode.auto,
    'always' || 'on' => modern_openai.XAISearchMode.on,
    'never' || 'off' => modern_openai.XAISearchMode.off,
    _ => null,
  };
}

List<modern_openai.XAISearchSource>? mapCompatXAISearchSources(
  List<SearchSource>? sources,
) {
  if (sources == null || sources.isEmpty) {
    return const [modern_openai.XAIWebSearchSource()];
  }

  final mapped = <modern_openai.XAISearchSource>[];
  for (final source in sources) {
    switch (source.sourceType) {
      case 'web':
        mapped.add(
          modern_openai.XAIWebSearchSource(
            excludedWebsites: source.excludedWebsites ?? const [],
          ),
        );
        break;
      case 'news':
        mapped.add(
          modern_openai.XAINewsSearchSource(
            excludedWebsites: source.excludedWebsites ?? const [],
          ),
        );
        break;
      default:
        return null;
    }
  }

  return mapped;
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
