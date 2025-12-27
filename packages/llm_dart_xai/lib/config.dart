import 'package:llm_dart_core/core/config.dart';
import 'package:llm_dart_core/core/provider_defaults.dart';
import 'package:llm_dart_core/core/provider_options.dart';
import 'package:llm_dart_core/models/tool_models.dart';

/// Search source configuration for search parameters.
class SearchSource {
  /// Type of source: "web" or "news".
  final String sourceType;

  /// List of websites to exclude from this source.
  final List<String>? excludedWebsites;

  const SearchSource({required this.sourceType, this.excludedWebsites});

  Map<String, dynamic> toJson() => {
        'type': sourceType,
        if (excludedWebsites != null) 'excluded_websites': excludedWebsites,
      };

  factory SearchSource.fromJson(Map<String, dynamic> json) {
    return SearchSource(
      sourceType:
          json['type'] as String? ?? json['sourceType'] as String? ?? 'web',
      excludedWebsites:
          (json['excluded_websites'] as List?)?.whereType<String>().toList() ??
              (json['excludedWebsites'] as List?)?.whereType<String>().toList(),
    );
  }
}

/// Search parameters for xAI Live Search.
///
/// Reference: https://docs.x.ai/docs/guides/live-search
class SearchParameters {
  /// "auto" | "always" | "never"
  final String? mode;

  /// Sources like "web" / "news".
  final List<SearchSource>? sources;

  /// Max number of search results included in context.
  final int? maxSearchResults;

  /// "YYYY-MM-DD"
  final String? fromDate;

  /// "YYYY-MM-DD"
  final String? toDate;

  const SearchParameters({
    this.mode,
    this.sources,
    this.maxSearchResults,
    this.fromDate,
    this.toDate,
  });

  factory SearchParameters.webSearch({
    String mode = 'auto',
    int? maxResults,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: mode,
      sources: [
        SearchSource(
          sourceType: 'web',
          excludedWebsites: excludedWebsites,
        ),
      ],
      maxSearchResults: maxResults,
    );
  }

  factory SearchParameters.newsSearch({
    String mode = 'auto',
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: mode,
      sources: [
        SearchSource(
          sourceType: 'news',
          excludedWebsites: excludedWebsites,
        ),
      ],
      maxSearchResults: maxResults,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  factory SearchParameters.combined({
    String mode = 'auto',
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: mode,
      sources: [
        SearchSource(
          sourceType: 'web',
          excludedWebsites: excludedWebsites,
        ),
        SearchSource(
          sourceType: 'news',
          excludedWebsites: excludedWebsites,
        ),
      ],
      maxSearchResults: maxResults,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Map<String, dynamic> toJson() => {
        if (mode != null) 'mode': mode,
        if (sources != null)
          'sources': sources!.map((s) => s.toJson()).toList(),
        if (maxSearchResults != null) 'max_search_results': maxSearchResults,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
      };

  factory SearchParameters.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'] ?? json['searchSources'];
    final List<SearchSource>? sources;
    if (rawSources is List) {
      sources = rawSources
          .whereType<Map>()
          .map((m) => SearchSource.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } else {
      sources = null;
    }

    int? maxResults;
    final rawMax = json['max_search_results'] ?? json['maxSearchResults'];
    if (rawMax is int) {
      maxResults = rawMax;
    } else if (rawMax is num) {
      maxResults = rawMax.toInt();
    }

    return SearchParameters(
      mode: json['mode'] as String?,
      sources: sources,
      maxSearchResults: maxResults,
      fromDate: json['from_date'] as String? ?? json['fromDate'] as String?,
      toDate: json['to_date'] as String? ?? json['toDate'] as String?,
    );
  }

  SearchParameters copyWith({
    String? mode,
    List<SearchSource>? sources,
    int? maxSearchResults,
    String? fromDate,
    String? toDate,
  }) {
    return SearchParameters(
      mode: mode ?? this.mode,
      sources: sources ?? this.sources,
      maxSearchResults: maxSearchResults ?? this.maxSearchResults,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

/// xAI provider configuration (Grok).
class XAIConfig {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final StructuredOutputFormat? jsonSchema;
  final String? embeddingEncodingFormat;
  final int? embeddingDimensions;
  final SearchParameters? searchParameters;
  final bool? liveSearch;

  final LLMConfig? _originalConfig;

  const XAIConfig({
    required this.apiKey,
    this.baseUrl = ProviderDefaults.xaiBaseUrl,
    this.model = ProviderDefaults.xaiDefaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.jsonSchema,
    this.embeddingEncodingFormat,
    this.embeddingDimensions,
    this.searchParameters,
    this.liveSearch,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  factory XAIConfig.fromLLMConfig(LLMConfig config) {
    const providerId = 'xai';
    final providerOptions = config.providerOptions;

    SearchParameters? searchParamsFromProviderOptions;
    final rawSearchParams = readProviderOptionMap(
            providerOptions, providerId, 'searchParameters') ??
        readProviderOption<dynamic>(
            providerOptions, providerId, 'searchParameters');
    if (rawSearchParams is SearchParameters) {
      searchParamsFromProviderOptions = rawSearchParams;
    } else if (rawSearchParams is Map<String, dynamic>) {
      searchParamsFromProviderOptions =
          SearchParameters.fromJson(rawSearchParams);
    } else if (rawSearchParams is Map) {
      searchParamsFromProviderOptions =
          SearchParameters.fromJson(Map<String, dynamic>.from(rawSearchParams));
    }

    final liveSearchFromProviderOptions =
        readProviderOption<bool>(providerOptions, providerId, 'liveSearch');

    final rawWebSearch = readProviderOptionMap(
            providerOptions, providerId, 'webSearch') ??
        readProviderOption<dynamic>(providerOptions, providerId, 'webSearch');
    final legacyWebSearchJson = _parseLegacyWebSearchJson(rawWebSearch);

    SearchParameters? searchParams = searchParamsFromProviderOptions;

    bool? liveSearchEnabled = liveSearchFromProviderOptions;

    final webSearchEnabledFromProviderOptions = readProviderOption<bool>(
        providerOptions, providerId, 'webSearchEnabled');

    final webSearchEnabled = webSearchEnabledFromProviderOptions;
    if (webSearchEnabled == true &&
        searchParams == null &&
        liveSearchEnabled != true) {
      liveSearchEnabled = true;
      searchParams = SearchParameters.webSearch();
    }

    if (legacyWebSearchJson != null && searchParams == null) {
      final enabled = _isLegacyWebSearchEnabled(legacyWebSearchJson);
      if (enabled) {
        searchParams =
            _convertLegacyWebSearchJsonToSearchParameters(legacyWebSearchJson);
        liveSearchEnabled = true;
      }
    } else if (rawWebSearch is bool &&
        rawWebSearch == true &&
        searchParams == null) {
      liveSearchEnabled = true;
      searchParams = SearchParameters.webSearch();
    }

    return XAIConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      systemPrompt: config.systemPrompt,
      timeout: config.timeout,
      topP: config.topP,
      topK: config.topK,
      tools: config.tools,
      toolChoice: config.toolChoice,
      jsonSchema: readProviderOption<StructuredOutputFormat>(
        providerOptions,
        providerId,
        'jsonSchema',
      ),
      embeddingEncodingFormat: readProviderOption<String>(
        providerOptions,
        providerId,
        'embeddingEncodingFormat',
      ),
      embeddingDimensions: readProviderOption<int>(
        providerOptions,
        providerId,
        'embeddingDimensions',
      ),
      searchParameters: searchParams,
      liveSearch: liveSearchEnabled,
      originalConfig: config,
    );
  }

  static Map<String, dynamic>? _parseLegacyWebSearchJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static bool _isLegacyWebSearchEnabled(Map<String, dynamic> json) {
    final enabled = json['enabled'];
    if (enabled is bool) return enabled;
    return true; // presence implies enabled (legacy behavior)
  }

  static SearchParameters _convertLegacyWebSearchJsonToSearchParameters(
    Map<String, dynamic> webSearchJson,
  ) {
    int? parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }

    List<String>? parseStringList(dynamic value) {
      if (value is List<String>) return value;
      if (value is List) return value.whereType<String>().toList();
      return null;
    }

    final excluded = parseStringList(
      webSearchJson['excluded_websites'] ??
          webSearchJson['excludedWebsites'] ??
          webSearchJson['blocked_domains'] ??
          webSearchJson['blockedDomains'],
    );

    final mode = (webSearchJson['mode'] as String?)?.trim().isNotEmpty == true
        ? (webSearchJson['mode'] as String).trim()
        : 'auto';

    final maxResults = parseInt(
      webSearchJson['max_search_results'] ??
          webSearchJson['maxSearchResults'] ??
          webSearchJson['max_results'] ??
          webSearchJson['maxResults'],
    );

    final fromDate = webSearchJson['from_date'] as String? ??
        webSearchJson['fromDate'] as String?;
    final toDate = webSearchJson['to_date'] as String? ??
        webSearchJson['toDate'] as String?;

    final rawType = webSearchJson['search_type'] ?? webSearchJson['searchType'];
    final searchType = rawType is String ? rawType : null;

    List<SearchSource> sourcesForType(String? type) {
      switch ((type ?? 'web').toLowerCase()) {
        case 'news':
          return [
            SearchSource(
              sourceType: 'news',
              excludedWebsites: excluded?.isNotEmpty == true ? excluded : null,
            ),
          ];
        case 'combined':
          return [
            SearchSource(
              sourceType: 'web',
              excludedWebsites: excluded?.isNotEmpty == true ? excluded : null,
            ),
            SearchSource(
              sourceType: 'news',
              excludedWebsites: excluded?.isNotEmpty == true ? excluded : null,
            ),
          ];
        case 'academic':
          return [
            SearchSource(
              sourceType: 'web',
              excludedWebsites: excluded?.isNotEmpty == true ? excluded : null,
            ),
          ];
        case 'web':
        default:
          return [
            SearchSource(
              sourceType: 'web',
              excludedWebsites: excluded?.isNotEmpty == true ? excluded : null,
            ),
          ];
      }
    }

    return SearchParameters(
      mode: mode,
      sources: sourcesForType(searchType),
      maxSearchResults: maxResults,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsReasoning => true;

  bool get supportsToolCalling => true;

  bool get supportsSearch => true;

  bool get supportsEmbeddings => true;

  bool get isLiveSearchEnabled =>
      (liveSearch == true) || searchParameters != null;

  String get modelFamily {
    // Intentionally avoid maintaining a model family matrix.
    return 'xAI';
  }

  bool get supportsVision => true;

  XAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? jsonSchema,
    String? embeddingEncodingFormat,
    int? embeddingDimensions,
    SearchParameters? searchParameters,
    bool? liveSearch,
  }) {
    return XAIConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      timeout: timeout ?? this.timeout,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      tools: tools ?? this.tools,
      toolChoice: toolChoice ?? this.toolChoice,
      jsonSchema: jsonSchema ?? this.jsonSchema,
      embeddingEncodingFormat:
          embeddingEncodingFormat ?? this.embeddingEncodingFormat,
      embeddingDimensions: embeddingDimensions ?? this.embeddingDimensions,
      searchParameters: searchParameters ?? this.searchParameters,
      liveSearch: liveSearch ?? this.liveSearch,
      originalConfig: _originalConfig,
    );
  }
}
