part of 'llm_builder.dart';

extension LLMBuilderWebSearchConfig on LLMBuilder {
  /// Enables web search functionality
  LLMBuilder enableWebSearch() =>
      extension(LegacyExtensionKeys.webSearchEnabled, true);

  /// Configures web search with detailed options
  LLMBuilder webSearch({
    int? maxUses,
    int? maxResults,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
    WebSearchLocation? location,
    String? mode,
    String? fromDate,
    String? toDate,
  }) {
    final config = WebSearchConfig(
      maxUses: maxUses,
      maxResults: maxResults,
      allowedDomains: allowedDomains,
      blockedDomains: blockedDomains,
      location: location ?? _currentWebSearchConfig?.location,
      mode: mode,
      fromDate: fromDate,
      toDate: toDate,
    );
    return extension(LegacyExtensionKeys.webSearchConfig, config);
  }

  /// Quick web search setup with basic options
  LLMBuilder quickWebSearch({
    int maxResults = 5,
    List<String>? blockedDomains,
  }) {
    return webSearch(
      maxResults: maxResults,
      blockedDomains: blockedDomains,
      mode: 'auto',
    );
  }

  /// Enables news search functionality
  LLMBuilder newsSearch({
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? blockedDomains,
  }) {
    final config = WebSearchConfig(
      maxResults: maxResults,
      fromDate: fromDate,
      toDate: toDate,
      blockedDomains: blockedDomains,
      location: _currentWebSearchConfig?.location,
      mode: 'auto',
      searchType: WebSearchType.news,
    );
    return extension(LegacyExtensionKeys.webSearchConfig, config);
  }

  /// Configures search location for localized results
  LLMBuilder searchLocation(WebSearchLocation location) {
    final nextConfig =
        (_currentWebSearchConfig ?? const WebSearchConfig()).copyWith(
      location: location,
    );
    return extension(LegacyExtensionKeys.webSearchConfig, nextConfig);
  }

  /// Advanced web search configuration with full control
  LLMBuilder advancedWebSearch({
    WebSearchStrategy? strategy,
    WebSearchContextSize? contextSize,
    String? searchPrompt,
    int? maxUses,
    int? maxResults,
    List<String>? allowedDomains,
    List<String>? blockedDomains,
    WebSearchLocation? location,
    String? mode,
    String? fromDate,
    String? toDate,
    WebSearchType? searchType,
  }) {
    final config = WebSearchConfig(
      strategy: strategy ?? WebSearchStrategy.auto,
      contextSize: contextSize,
      searchPrompt: searchPrompt,
      maxUses: maxUses,
      maxResults: maxResults,
      allowedDomains: allowedDomains,
      blockedDomains: blockedDomains,
      location: location ?? _currentWebSearchConfig?.location,
      mode: mode,
      fromDate: fromDate,
      toDate: toDate,
      searchType: searchType,
    );
    return extension(LegacyExtensionKeys.webSearchConfig, config);
  }
}
