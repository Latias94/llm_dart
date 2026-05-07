/// Unified web search configuration for multi-provider support
///
/// This module provides a provider-agnostic interface for configuring
/// web search functionality across different LLM providers.
library;

/// Types of web search
enum WebSearchType {
  /// General web search
  web,

  /// News-specific search
  news,

  /// Academic/scholarly search
  academic,

  /// Combined web and news search
  combined,
}

/// Search context size for providers that support it
enum WebSearchContextSize {
  /// Minimal search context, suitable for basic queries
  low,

  /// Moderate search context, good for general queries
  medium,

  /// Extensive search context, ideal for detailed research
  high,
}

/// Web search implementation strategy
enum WebSearchStrategy {
  /// Use a provider's native search integration
  native,

  /// Use tool-based search
  tool,

  /// Use plugin-based search
  plugin,

  /// Use parameter-based search
  parameter,

  /// Auto-detect best strategy for provider
  auto,
}

/// Geographic location for search localization
class WebSearchLocation {
  /// City name
  final String? city;

  /// State/region name
  final String? region;

  /// Country name or code
  final String? country;

  /// IANA timezone identifier
  final String? timezone;

  /// Location type (e.g., "approximate")
  final String? type;

  const WebSearchLocation({
    this.city,
    this.region,
    this.country,
    this.timezone,
    this.type = 'approximate',
  });

  /// Create location for San Francisco
  factory WebSearchLocation.sanFrancisco() => const WebSearchLocation(
        city: 'San Francisco',
        region: 'California',
        country: 'US',
        timezone: 'America/Los_Angeles',
      );

  /// Create location for New York
  factory WebSearchLocation.newYork() => const WebSearchLocation(
        city: 'New York',
        region: 'New York',
        country: 'US',
        timezone: 'America/New_York',
      );

  /// Create location for London
  factory WebSearchLocation.london() => const WebSearchLocation(
        city: 'London',
        region: 'England',
        country: 'GB',
        timezone: 'Europe/London',
      );

  /// Create location for Tokyo
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

/// Unified web search configuration
///
/// This class provides a provider-agnostic way to configure web search
/// functionality. Different providers will interpret these settings
/// according to their specific API requirements.
class WebSearchConfig {
  /// Maximum number of search operations per request
  final int? maxUses;

  /// Maximum number of search results to return
  final int? maxResults;

  /// List of allowed domains (whitelist)
  final List<String>? allowedDomains;

  /// List of blocked domains (blacklist)
  final List<String>? blockedDomains;

  /// Geographic location for search localization
  final WebSearchLocation? location;

  /// Search mode/strategy
  final String? mode;

  /// Start date for search results (YYYY-MM-DD format)
  final String? fromDate;

  /// End date for search results (YYYY-MM-DD format)
  final String? toDate;

  /// Type of search (web, news, etc.)
  final WebSearchType? searchType;

  /// Search context size for providers that support it
  final WebSearchContextSize? contextSize;

  /// Custom search prompt for result integration
  final String? searchPrompt;

  /// Web search implementation strategy
  ///
  /// Controls how the search is implemented for each provider.
  /// Most users should use `auto` to let the system choose the best strategy.
  final WebSearchStrategy strategy;

  /// Whether web search is enabled
  final bool enabled;

  const WebSearchConfig({
    this.maxUses,
    this.maxResults,
    this.allowedDomains,
    this.blockedDomains,
    this.location,
    this.mode,
    this.fromDate,
    this.toDate,
    this.searchType,
    this.contextSize,
    this.searchPrompt,
    this.strategy = WebSearchStrategy.auto,
    this.enabled = true,
  });

  /// Create a basic web search configuration
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

  /// Create a news search configuration
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

  WebSearchConfig copyWith({
    int? maxUses,
    int? maxResults,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
    WebSearchLocation? location,
    String? mode,
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
        if (fromDate != null) 'from_date': fromDate,
        if (toDate != null) 'to_date': toDate,
        if (searchType != null) 'search_type': searchType!.name,
        if (contextSize != null) 'context_size': contextSize!.name,
        if (searchPrompt != null) 'search_prompt': searchPrompt,
        'strategy': strategy.name,
        'enabled': enabled,
      };

  @override
  String toString() => 'WebSearchConfig(enabled: $enabled, type: $searchType, '
      'maxResults: $maxResults, maxUses: $maxUses)';
}
