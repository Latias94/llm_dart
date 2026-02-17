import 'package:llm_dart_core/llm_dart_core.dart';

import 'defaults.dart';

/// Search source configuration for search parameters.
class SearchSource {
  /// Type of source: "web" | "x" | "news" | "rss".
  final String sourceType;

  /// Optional country code (e.g. "US", "GB").
  final String? country;

  /// List of websites to exclude from this source.
  final List<String>? excludedWebsites;

  /// List of websites to allow for this source (web only).
  final List<String>? allowedWebsites;

  /// Safe search flag (web/news only).
  final bool? safeSearch;

  /// List of X handles to exclude (x only).
  final List<String>? excludedXHandles;

  /// List of X handles to include (x only).
  final List<String>? includedXHandles;

  /// Deprecated alias for included X handles (x only).
  final List<String>? xHandles;

  /// Minimum favorite count filter (x only).
  final int? postFavoriteCount;

  /// Minimum view count filter (x only).
  final int? postViewCount;

  /// RSS feed links (rss only). Currently most APIs support a single link.
  final List<String>? links;

  const SearchSource({
    required this.sourceType,
    this.country,
    this.excludedWebsites,
    this.allowedWebsites,
    this.safeSearch,
    this.excludedXHandles,
    this.includedXHandles,
    this.xHandles,
    this.postFavoriteCount,
    this.postViewCount,
    this.links,
  });

  static List<String>? _parseStringList(dynamic value) {
    if (value is List<String>) return value;
    if (value is List) return value.whereType<String>().toList();
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    final type = sourceType.trim().isEmpty ? 'web' : sourceType.trim();
    final lower = type.toLowerCase();

    final json = <String, dynamic>{
      'type': lower,
    };

    switch (lower) {
      case 'web':
        if (country != null) json['country'] = country;
        if (excludedWebsites != null) {
          json['excluded_websites'] = excludedWebsites;
        }
        if (allowedWebsites != null) json['allowed_websites'] = allowedWebsites;
        if (safeSearch != null) json['safe_search'] = safeSearch;
        return json;

      case 'news':
        if (country != null) json['country'] = country;
        if (excludedWebsites != null) {
          json['excluded_websites'] = excludedWebsites;
        }
        if (safeSearch != null) json['safe_search'] = safeSearch;
        return json;

      case 'x':
        if (excludedXHandles != null) {
          json['excluded_x_handles'] = excludedXHandles;
        }
        final included = includedXHandles ?? xHandles;
        if (included != null) json['included_x_handles'] = included;
        if (postFavoriteCount != null) {
          json['post_favorite_count'] = postFavoriteCount;
        }
        if (postViewCount != null) json['post_view_count'] = postViewCount;
        return json;

      case 'rss':
        if (links != null) json['links'] = links;
        return json;

      default:
        return json;
    }
  }

  factory SearchSource.fromJson(Map<String, dynamic> json) {
    return SearchSource(
      sourceType:
          json['type'] as String? ?? json['sourceType'] as String? ?? 'web',
      country: json['country'] as String?,
      excludedWebsites: _parseStringList(json['excluded_websites']) ??
          _parseStringList(json['excludedWebsites']),
      allowedWebsites: _parseStringList(json['allowed_websites']) ??
          _parseStringList(json['allowedWebsites']),
      safeSearch: json['safe_search'] as bool? ?? json['safeSearch'] as bool?,
      excludedXHandles: _parseStringList(json['excluded_x_handles']) ??
          _parseStringList(json['excludedXHandles']),
      includedXHandles: _parseStringList(json['included_x_handles']) ??
          _parseStringList(json['includedXHandles']),
      xHandles: _parseStringList(json['xHandles']),
      postFavoriteCount: _parseInt(
        json['post_favorite_count'] ?? json['postFavoriteCount'],
      ),
      postViewCount:
          _parseInt(json['post_view_count'] ?? json['postViewCount']),
      links: _parseStringList(json['links']),
    );
  }
}

/// Search parameters for xAI Live Search.
///
/// Reference: https://docs.x.ai/docs/guides/live-search
class SearchParameters {
  /// Search mode preference: "off" | "auto" | "on".
  final String? mode;

  /// Whether to return citations.
  final bool? returnCitations;

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
    this.returnCitations,
    this.sources,
    this.maxSearchResults,
    this.fromDate,
    this.toDate,
  });

  static String? _normalizeMode(String? raw) {
    final v = raw?.trim();
    if (v == null || v.isEmpty) return null;
    return v.toLowerCase();
  }

  factory SearchParameters.webSearch({
    String mode = 'auto',
    bool? returnCitations,
    int? maxResults,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: _normalizeMode(mode),
      returnCitations: returnCitations,
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
    bool? returnCitations,
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: _normalizeMode(mode),
      returnCitations: returnCitations,
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
    bool? returnCitations,
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return SearchParameters(
      mode: _normalizeMode(mode),
      returnCitations: returnCitations,
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
        if (_normalizeMode(mode) != null) 'mode': _normalizeMode(mode),
        if (returnCitations != null) 'return_citations': returnCitations,
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
      mode: _normalizeMode(json['mode'] as String?),
      returnCitations:
          json['return_citations'] as bool? ?? json['returnCitations'] as bool?,
      sources: sources,
      maxSearchResults: maxResults,
      fromDate: json['from_date'] as String? ?? json['fromDate'] as String?,
      toDate: json['to_date'] as String? ?? json['toDate'] as String?,
    );
  }

  SearchParameters copyWith({
    String? mode,
    bool? returnCitations,
    List<SearchSource>? sources,
    int? maxSearchResults,
    String? fromDate,
    String? toDate,
  }) {
    return SearchParameters(
      mode: _normalizeMode(mode ?? this.mode),
      returnCitations: returnCitations ?? this.returnCitations,
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
  final String imageModel;
  final String videoModel;
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
    this.baseUrl = xaiBaseUrl,
    this.model = xaiDefaultModel,
    this.imageModel = xaiDefaultImageModel,
    this.videoModel = xaiDefaultVideoModel,
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

    SearchParameters? searchParams = searchParamsFromProviderOptions;

    bool? liveSearchEnabled = liveSearchFromProviderOptions;

    if (liveSearchEnabled == true && searchParams == null) {
      searchParams = SearchParameters.webSearch();
    }

    searchParams = searchParams?.copyWith();

    final imageModelFromProviderOptions = readProviderOption<String>(
          providerOptions,
          providerId,
          'imageModel',
        ) ??
        readProviderOption<String>(
          providerOptions,
          providerId,
          'imageModelId',
        );

    final videoModelFromProviderOptions = readProviderOption<String>(
          providerOptions,
          providerId,
          'videoModel',
        ) ??
        readProviderOption<String>(
          providerOptions,
          providerId,
          'videoModelId',
        );

    return XAIConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      imageModel: (imageModelFromProviderOptions?.trim().isNotEmpty == true)
          ? imageModelFromProviderOptions!.trim()
          : xaiDefaultImageModel,
      videoModel: (videoModelFromProviderOptions?.trim().isNotEmpty == true)
          ? videoModelFromProviderOptions!.trim()
          : xaiDefaultVideoModel,
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
    String? imageModel,
    String? videoModel,
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
      imageModel: imageModel ?? this.imageModel,
      videoModel: videoModel ?? this.videoModel,
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
