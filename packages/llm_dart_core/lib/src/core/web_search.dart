/// Unified web search configuration for multi-provider support.
///
/// This module provides a provider-agnostic interface for configuring
/// web search functionality across different LLM providers.

/// Types of web search.
enum WebSearchType {
  /// General web search.
  web,

  /// News-specific search.
  news,

  /// Academic/scholarly search.
  academic,

  /// Combined web and news search.
  combined,
}

/// Search context size for providers that support it.
enum WebSearchContextSize {
  /// Minimal search context, suitable for basic queries.
  low,

  /// Moderate search context, good for general queries.
  medium,

  /// Extensive search context, ideal for detailed research.
  high,
}

/// Web search implementation strategy.
enum WebSearchStrategy {
  /// Use provider's native search (OpenAI, Perplexity).
  native,

  /// Use tool-based search (Anthropic, OpenAI tools).
  tool,

  /// Use plugin-based search (OpenRouter).
  plugin,

  /// Use parameter-based search (xAI).
  parameter,

  /// Auto-detect best strategy for provider.
  auto,
}

/// Geographic location for search localization.
class WebSearchLocation {
  /// City name.
  final String? city;

  /// State/region name.
  final String? region;

  /// Country name or code.
  final String? country;

  /// IANA timezone identifier.
  final String? timezone;

  /// Location type (e.g., "approximate").
  final String? type;

  const WebSearchLocation({
    this.city,
    this.region,
    this.country,
    this.timezone,
    this.type = 'approximate',
  });

  /// Create location for San Francisco.
  factory WebSearchLocation.sanFrancisco() => const WebSearchLocation(
        city: 'San Francisco',
        region: 'California',
        country: 'US',
        timezone: 'America/Los_Angeles',
      );

  /// Create location for New York.
  factory WebSearchLocation.newYork() => const WebSearchLocation(
        city: 'New York',
        region: 'New York',
        country: 'US',
        timezone: 'America/New_York',
      );

  /// Create location for London.
  factory WebSearchLocation.london() => const WebSearchLocation(
        city: 'London',
        region: 'England',
        country: 'GB',
        timezone: 'Europe/London',
      );

  /// Create location for Tokyo.
  factory WebSearchLocation.tokyo() => const WebSearchLocation(
        city: 'Tokyo',
        region: 'Tokyo',
        country: 'JP',
        timezone: 'Asia/Tokyo',
      );

  Map<String, dynamic> toJson() => {
        if (type != null) 'type': type,
        if (city != null) 'city': city,
        if (region != null) 'region': region,
        if (country != null) 'country': country,
        if (timezone != null) 'timezone': timezone,
      };

  @override
  String toString() => 'WebSearchLocation($city, $region, $country)';
}

/// Unified web search configuration.
///
/// This class provides a provider-agnostic way to configure web search
/// functionality. Different providers will interpret these settings
/// according to their specific API requirements.
class WebSearchConfig {
  /// Maximum number of search operations per request.
  ///
  /// - **Anthropic**: Maps to `max_uses` parameter.
  /// - **xAI**: Not directly supported, but can limit search frequency.
  final int? maxUses;

  /// Maximum number of search results to return.
  ///
  /// - **Anthropic**: Controlled by the search engine.
  /// - **xAI**: Maps to `max_search_results` parameter.
  final int? maxResults;

  /// List of allowed domains (whitelist).
  ///
  /// - **Anthropic**: Maps to `allowed_domains` parameter.
  /// - **xAI**: Can be implemented via excluded websites (inverse logic).
  final List<String>? allowedDomains;

  /// List of blocked domains (blacklist).
  ///
  /// - **Anthropic**: Maps to `blocked_domains` parameter.
  /// - **xAI**: Maps to `excluded_websites` parameter.
  final List<String>? blockedDomains;

  /// Geographic location for search localization.
  ///
  /// - **Anthropic**: Maps to `user_location` parameter.
  /// - **xAI**: Not directly supported, but can be included in search context.
  final WebSearchLocation? location;

  /// Search mode/strategy.
  ///
  /// - **Anthropic**: Not directly applicable (tool-based).
  /// - **xAI**: Maps to `mode` parameter ("auto", "always", "never").
  final String? mode;

  /// Dynamic retrieval threshold for providers that support it.
  ///
  /// - **Google**: Maps to `dynamicRetrievalConfig.dynamicThreshold`.
  /// - **Others**: Not used.
  final double? dynamicThreshold;

  /// Start date for search results (YYYY-MM-DD format).
  ///
  /// - **Anthropic**: Not directly supported.
  /// - **xAI**: Maps to `from_date` parameter.
  final String? fromDate;

  /// End date for search results (YYYY-MM-DD format).
  ///
  /// - **Anthropic**: Not directly supported.
  /// - **xAI**: Maps to `to_date` parameter.
  final String? toDate;

  /// Type of search (web, news, etc.).
  final WebSearchType? searchType;

  /// Search context size for providers that support it.
  ///
  /// - **OpenAI**: Maps to `web_search_options.search_context_size`.
  /// - **Perplexity**: Maps to search context size parameter.
  /// - **OpenRouter**: Not directly supported.
  /// - **xAI/Anthropic**: Not applicable.
  final WebSearchContextSize? contextSize;

  /// Custom search prompt for result integration.
  ///
  /// - **OpenRouter**: Maps to `search_prompt` parameter.
  /// - **Others**: Not directly supported, but can influence system prompts.
  final String? searchPrompt;

  /// Web search implementation strategy.
  ///
  /// Controls how the search is implemented for each provider.
  /// Most users should use `auto` to let the system choose the best strategy.
  final WebSearchStrategy strategy;

  /// Whether web search is enabled.
  final bool enabled;

  const WebSearchConfig({
    this.maxUses,
    this.maxResults,
    this.allowedDomains,
    this.blockedDomains,
    this.location,
    this.mode,
    this.dynamicThreshold,
    this.fromDate,
    this.toDate,
    this.searchType,
    this.contextSize,
    this.searchPrompt,
    this.strategy = WebSearchStrategy.auto,
    this.enabled = true,
  });

  /// Create a basic web search configuration.
  factory WebSearchConfig.basic({
    int maxResults = 5,
    List<String>? blockedDomains,
  }) =>
      WebSearchConfig(
        maxResults: maxResults,
        blockedDomains: blockedDomains,
        mode: 'auto',
        searchType: WebSearchType.web,
      );

  /// Create a news search configuration.
  factory WebSearchConfig.news({
    int maxResults = 10,
    String? fromDate,
    String? toDate,
  }) =>
      WebSearchConfig(
        maxResults: maxResults,
        fromDate: fromDate,
        toDate: toDate,
        mode: 'auto',
        searchType: WebSearchType.news,
      );

  /// Create an Anthropic-optimized configuration.
  factory WebSearchConfig.anthropic({
    int maxUses = 5,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
    WebSearchLocation? location,
  }) =>
      WebSearchConfig(
        maxUses: maxUses,
        allowedDomains: allowedDomains,
        blockedDomains: blockedDomains,
        location: location,
        searchType: WebSearchType.web,
      );

  /// Create an xAI-optimized configuration.
  factory WebSearchConfig.xai({
    int maxResults = 5,
    List<String>? blockedDomains,
    String mode = 'auto',
    String? fromDate,
    String? toDate,
    WebSearchType searchType = WebSearchType.web,
  }) =>
      WebSearchConfig(
        maxResults: maxResults,
        blockedDomains: blockedDomains,
        mode: mode,
        fromDate: fromDate,
        toDate: toDate,
        searchType: searchType,
        strategy: WebSearchStrategy.parameter,
      );

  WebSearchConfig copyWith({
    int? maxUses,
    int? maxResults,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
    WebSearchLocation? location,
    String? mode,
    double? dynamicThreshold,
    String? fromDate,
    String? toDate,
    WebSearchType? searchType,
    WebSearchContextSize? contextSize,
    String? searchPrompt,
    WebSearchStrategy? strategy,
    bool? enabled,
  }) =>
      WebSearchConfig(
        maxUses: maxUses ?? this.maxUses,
        maxResults: maxResults ?? this.maxResults,
        allowedDomains: allowedDomains ?? this.allowedDomains,
        blockedDomains: blockedDomains ?? this.blockedDomains,
        location: location ?? this.location,
        mode: mode ?? this.mode,
        dynamicThreshold: dynamicThreshold ?? this.dynamicThreshold,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        searchType: searchType ?? this.searchType,
        contextSize: contextSize ?? this.contextSize,
        searchPrompt: searchPrompt ?? this.searchPrompt,
        strategy: strategy ?? this.strategy,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        if (maxUses != null) 'max_uses': maxUses,
        if (maxResults != null) 'max_results': maxResults,
        if (allowedDomains != null) 'allowed_domains': allowedDomains,
        if (blockedDomains != null) 'blocked_domains': blockedDomains,
        if (location != null) 'location': location!.toJson(),
        if (mode != null) 'mode': mode,
        if (dynamicThreshold != null) 'dynamic_threshold': dynamicThreshold,
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (searchType != null) 'search_type': searchType!.name,
        if (contextSize != null) 'context_size': contextSize!.name,
        if (searchPrompt != null) 'search_prompt': searchPrompt,
        'strategy': strategy.name,
        'enabled': enabled,
      };

  /// Create an OpenAI-optimized configuration.
  factory WebSearchConfig.openai({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
    WebSearchStrategy strategy = WebSearchStrategy.auto,
  }) =>
      WebSearchConfig(
        contextSize: contextSize,
        strategy: strategy,
        searchType: WebSearchType.web,
      );

  /// Create an OpenRouter-optimized configuration.
  factory WebSearchConfig.openRouter({
    int maxResults = 5,
    String? searchPrompt,
    bool useOnlineShortcut = true,
  }) =>
      WebSearchConfig(
        maxResults: maxResults,
        searchPrompt: searchPrompt,
        strategy: useOnlineShortcut
            ? WebSearchStrategy.plugin
            : WebSearchStrategy.plugin,
        searchType: WebSearchType.web,
      );

  /// Create a Perplexity-optimized configuration.
  factory WebSearchConfig.perplexity({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
  }) =>
      WebSearchConfig(
        contextSize: contextSize,
        strategy: WebSearchStrategy.native,
        searchType: WebSearchType.web,
      );

  @override
  String toString() => 'WebSearchConfig(enabled: $enabled, type: $searchType, '
      'maxResults: $maxResults, maxUses: $maxUses)';
}
