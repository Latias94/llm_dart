import 'package:llm_dart_openai/llm_dart_openai.dart' as modern_openai;

import '../../../core/config.dart';
import '../../../providers/xai/config.dart';
import '../compat_value_utils.dart';
import '../config/legacy_xai_options.dart';
import '../config/legacy_provider_options.dart';
import 'legacy_dio_client_overrides.dart';

/// Adapts a legacy root `LLMConfig` into an xAI provider config.
XAIConfig createLegacyXAIConfig(LLMConfig config) {
  final options = legacyProviderOptionView(
    config,
    LegacyProviderOptionNamespaces.xai,
  );
  final xaiOptions = legacyXAIOptions(options);

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
    jsonSchema: xaiOptions.jsonSchema,
    embeddingEncodingFormat: xaiOptions.embeddingEncodingFormat,
    embeddingDimensions: xaiOptions.embeddingDimensions,
    searchParameters: xaiOptions.searchParameters,
    liveSearch: xaiOptions.liveSearch,
  );
}

modern_openai.XAIGenerateTextOptions buildCompatXAIInvocationOptions(
  XAIConfig config,
) {
  return modern_openai.XAIGenerateTextOptions(
    common: const modern_openai.OpenAIGenerateTextOptions(),
    search: buildCompatXAILiveSearchOptions(config),
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
