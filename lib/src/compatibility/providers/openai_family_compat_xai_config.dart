import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/tool_models.dart';
import '../../../providers/xai/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';
import '../config/legacy_web_search_options.dart';
import 'community_provider_config_adapters.dart';
import 'compat_provider_support.dart';

/// Adapts a legacy root `LLMConfig` into an xAI provider config.
XAIConfig createLegacyXAIConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.xai,
  );
  final searchParameters = _createLegacyXAISearchParameters(options);
  final liveSearchEnabled = options.getWithFlatFallback<bool>(
    LegacyExtensionKeys.xaiLiveSearch,
  );

  return XAIConfig(
    apiKey: config.apiKey!,
    baseUrl: config.baseUrl,
    model: config.model,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    systemPrompt: config.systemPrompt,
    timeout: config.timeout,
    dioOverrides: createLegacyDioClientOverrides(config),
    topP: config.topP,
    topK: config.topK,
    tools: config.tools,
    toolChoice: config.toolChoice,
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    embeddingEncodingFormat: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
    searchParameters: searchParameters,
    liveSearch: liveSearchEnabled ?? searchParameters != null,
  );
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

SearchParameters? _createLegacyXAISearchParameters(
  LegacyProviderOptionView options,
) {
  final searchParameters = options.getWithFlatFallback<SearchParameters>(
    LegacyExtensionKeys.xaiSearchParameters,
  );
  if (searchParameters != null) {
    return searchParameters;
  }

  final webSearchOptions = legacyWebSearchOptions(options);
  final webSearchConfig = webSearchOptions.config;
  if (webSearchConfig != null) {
    return _convertWebSearchConfigToSearchParameters(webSearchConfig);
  }

  if (webSearchOptions.enabled) {
    return SearchParameters.webSearch();
  }

  return null;
}

SearchParameters _convertWebSearchConfigToSearchParameters(
  WebSearchConfig config,
) {
  final sourceType = config.searchType == WebSearchType.news ? 'news' : 'web';

  return SearchParameters(
    mode: config.mode ?? 'auto',
    sources: [
      SearchSource(
        sourceType: sourceType,
        excludedWebsites: config.blockedDomains,
      ),
    ],
    maxSearchResults: config.maxResults,
    fromDate: config.fromDate,
    toDate: config.toDate,
  );
}
