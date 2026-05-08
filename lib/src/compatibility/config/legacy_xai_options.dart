import '../../../core/web_search.dart';
import '../../../models/tool_models.dart';
import '../../../providers/xai/config.dart';
import 'legacy_config_keys.dart';
import 'legacy_provider_options.dart';
import 'legacy_web_search_options.dart';

final class LegacyXAIOptions {
  final StructuredOutputFormat? jsonSchema;
  final String? embeddingEncodingFormat;
  final int? embeddingDimensions;
  final SearchParameters? searchParameters;
  final bool? liveSearchEnabled;

  const LegacyXAIOptions({
    required this.jsonSchema,
    required this.embeddingEncodingFormat,
    required this.embeddingDimensions,
    required this.searchParameters,
    required this.liveSearchEnabled,
  });

  bool get liveSearch => liveSearchEnabled ?? searchParameters != null;
}

LegacyXAIOptions legacyXAIOptions(
  LegacyProviderOptionView options,
) {
  return LegacyXAIOptions(
    jsonSchema: options.getWithFlatFallback<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    embeddingEncodingFormat: options.getWithFlatFallback<String>(
      LegacyExtensionKeys.embeddingEncodingFormat,
    ),
    embeddingDimensions: options.getWithFlatFallback<int>(
      LegacyExtensionKeys.embeddingDimensions,
    ),
    searchParameters: _legacyXAISearchParameters(options),
    liveSearchEnabled: options.getWithFlatFallback<bool>(
      LegacyExtensionKeys.xaiLiveSearch,
    ),
  );
}

SearchParameters? _legacyXAISearchParameters(
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
