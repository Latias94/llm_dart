import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides;

import '../../models/tool_models.dart';
import 'defaults.dart';

/// Search source configuration for search parameters
class SearchSource {
  /// Type of source: "web" or "news"
  final String sourceType;

  /// List of websites to exclude from this source
  final List<String>? excludedWebsites;

  const SearchSource({required this.sourceType, this.excludedWebsites});

  Map<String, dynamic> toJson() => {
        'type': sourceType,
        if (excludedWebsites != null) 'excluded_websites': excludedWebsites,
      };
}

/// Search parameters for LLM providers that support search functionality
///
/// This class configures search behavior for providers like xAI Grok that support
/// real-time web search capabilities. The parameters follow xAI's Live Search API specification.
///
/// **Reference:** https://docs.x.ai/docs/guides/live-search
class SearchParameters {
  /// Search mode (e.g., "auto")
  ///
  /// Controls how the search is triggered:
  /// - "auto": Automatically search when relevant
  /// - "always": Always perform search
  /// - "never": Never perform search
  final String? mode;

  /// List of search sources with exclusions
  ///
  /// Defines which sources to search and which websites to exclude.
  /// Common source types: "web", "news"
  final List<SearchSource>? sources;

  /// Maximum number of search results to return
  ///
  /// Controls the number of search results to include in the context.
  /// Higher values provide more information but use more tokens.
  final int? maxSearchResults;

  /// Start date for search results (format: "YYYY-MM-DD")
  ///
  /// Filters search results to only include content from this date onwards.
  /// Useful for finding recent information.
  final String? fromDate;

  /// End date for search results (format: "YYYY-MM-DD")
  ///
  /// Filters search results to only include content up to this date.
  /// Useful for historical searches.
  final String? toDate;

  const SearchParameters({
    this.mode,
    this.sources,
    this.maxSearchResults,
    this.fromDate,
    this.toDate,
  });

  /// Creates search parameters with default web search configuration
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

  /// Creates search parameters for news search
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

  /// Creates search parameters for both web and news sources
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

  @override
  String toString() {
    return 'SearchParameters(mode: $mode, sources: ${sources?.length}, '
        'maxResults: $maxSearchResults, fromDate: $fromDate, toDate: $toDate)';
  }
}

/// xAI provider configuration
///
/// This class contains all configuration options for the xAI providers.
/// It's extracted from the main provider to improve modularity and reusability.
class XAIConfig implements HasDioClientOverrides {
  final String apiKey;
  final String baseUrl;
  final String model;
  final int? maxTokens;
  final double? temperature;
  final String? systemPrompt;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;

  final double? topP;
  final int? topK;
  final List<Tool>? tools;
  final ToolChoice? toolChoice;
  final StructuredOutputFormat? jsonSchema;
  final String? embeddingEncodingFormat;
  final int? embeddingDimensions;
  final SearchParameters? searchParameters;

  /// Enable or disable live search functionality
  ///
  /// When enabled, the model can perform real-time web searches to provide
  /// current information. This is particularly useful for Grok models.
  ///
  /// **Note:** Live search is only available for certain xAI models and
  /// requires appropriate API access. Setting this to true will automatically
  /// configure basic search parameters if none are provided.
  final bool? liveSearch;

  const XAIConfig({
    required this.apiKey,
    this.baseUrl = XAIDefaults.baseUrl,
    this.model = XAIDefaults.defaultModel,
    this.maxTokens,
    this.temperature,
    this.systemPrompt,
    this.timeout,
    this.dioOverrides,
    this.topP,
    this.topK,
    this.tools,
    this.toolChoice,
    this.jsonSchema,
    this.embeddingEncodingFormat,
    this.embeddingDimensions,
    this.searchParameters,
    this.liveSearch,
  });

  /// Check if this model supports reasoning/thinking
  bool get supportsReasoning {
    // Grok models are designed for reasoning and thinking
    return model.contains('grok');
  }

  /// Check if this model supports vision
  bool get supportsVision {
    // Grok Vision models support vision
    return model.contains('vision') || model.contains('grok-vision');
  }

  /// Check if this model supports tool calling
  bool get supportsToolCalling {
    // xAI supports function calling as of October 2024
    // Reference: https://docs.x.ai/docs/guides/function-calling
    return true;
  }

  /// Check if this model supports search
  bool get supportsSearch {
    // Grok models have access to real-time information
    return model.contains('grok');
  }

  /// Check if live search is enabled
  bool get isLiveSearchEnabled {
    // Live search is enabled if explicitly set to true, or if search parameters are configured
    return liveSearch == true || searchParameters != null;
  }

  /// Check if this model supports embeddings
  bool get supportsEmbeddings {
    // xAI provides embedding models
    return model.contains('embed') || model == 'text-embedding-ada-002';
  }

  /// Get the model family
  String get modelFamily {
    if (model.contains('grok')) return 'Grok';
    if (model.contains('embed')) return 'Embedding';
    return 'Unknown';
  }

  XAIConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    int? maxTokens,
    double? temperature,
    String? systemPrompt,
    Duration? timeout,
    DioClientOverrides? dioOverrides,
    double? topP,
    int? topK,
    List<Tool>? tools,
    ToolChoice? toolChoice,
    StructuredOutputFormat? jsonSchema,
    String? embeddingEncodingFormat,
    int? embeddingDimensions,
    SearchParameters? searchParameters,
    bool? liveSearch,
  }) =>
      XAIConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        model: model ?? this.model,
        maxTokens: maxTokens ?? this.maxTokens,
        temperature: temperature ?? this.temperature,
        systemPrompt: systemPrompt ?? this.systemPrompt,
        timeout: timeout ?? this.timeout,
        dioOverrides: dioOverrides ?? this.dioOverrides,
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
      );
}
