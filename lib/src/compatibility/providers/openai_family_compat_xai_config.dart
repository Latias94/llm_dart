import '../../../core/config.dart';
import '../../../core/web_search.dart';
import '../../../models/tool_models.dart';
import '../../../providers/xai/config.dart';
import '../../config/legacy_config_keys.dart';
import 'community_provider_config_adapters.dart';

/// Adapts a legacy root `LLMConfig` into an xAI provider config.
XAIConfig createLegacyXAIConfig(LLMConfig config) {
  final searchParameters = _createLegacyXAISearchParameters(config);
  final liveSearchEnabled = config.getExtension<bool>('liveSearch');

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
    jsonSchema: config.getExtension<StructuredOutputFormat>(
      LegacyExtensionKeys.jsonSchema,
    ),
    embeddingEncodingFormat: config
        .getExtension<String>(LegacyExtensionKeys.embeddingEncodingFormat),
    embeddingDimensions:
        config.getExtension<int>(LegacyExtensionKeys.embeddingDimensions),
    searchParameters: searchParameters,
    liveSearch: liveSearchEnabled ?? searchParameters != null,
  );
}

SearchParameters? _createLegacyXAISearchParameters(LLMConfig config) {
  final searchParameters =
      config.getExtension<SearchParameters>('searchParameters');
  if (searchParameters != null) {
    return searchParameters;
  }

  final webSearchConfig = config.getExtension<WebSearchConfig>(
    LegacyExtensionKeys.webSearchConfig,
  );
  if (webSearchConfig != null) {
    return _convertWebSearchConfigToSearchParameters(webSearchConfig);
  }

  if (config.getExtension<bool>(LegacyExtensionKeys.webSearchEnabled) == true) {
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
