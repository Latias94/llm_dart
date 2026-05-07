import '../../core/web_search.dart';

/// Provider-oriented web search presets for the legacy compatibility surface.
final class CompatWebSearchPresets {
  const CompatWebSearchPresets._();

  /// Create an Anthropic-oriented configuration.
  static WebSearchConfig anthropic({
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

  /// Create an xAI-oriented configuration.
  static WebSearchConfig xai({
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

  /// Create an OpenAI-oriented configuration.
  static WebSearchConfig openai({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
    WebSearchStrategy strategy = WebSearchStrategy.auto,
  }) =>
      WebSearchConfig(
        contextSize: contextSize,
        strategy: strategy,
        searchType: WebSearchType.web,
      );

  /// Create an OpenRouter-oriented configuration.
  static WebSearchConfig openRouter({
    int maxResults = 5,
    String? searchPrompt,
    bool useOnlineShortcut = true,
  }) =>
      WebSearchConfig(
        maxResults: maxResults,
        searchPrompt: searchPrompt,
        strategy: WebSearchStrategy.plugin,
        searchType: WebSearchType.web,
      );

  /// Create a Perplexity-oriented configuration.
  static WebSearchConfig perplexity({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
  }) =>
      WebSearchConfig(
        contextSize: contextSize,
        strategy: WebSearchStrategy.native,
        searchType: WebSearchType.web,
      );
}
