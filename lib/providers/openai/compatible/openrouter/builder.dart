import '../../../../builder/llm_builder.dart';
import '../../../../core/capability.dart';
import '../../../../core/config.dart';
import '../../../../core/web_search.dart';

/// OpenRouter-specific LLM builder with provider-specific configuration methods
///
/// This builder provides a layered configuration approach where OpenRouter-specific
/// parameters are handled separately from the generic LLMBuilder, keeping the
/// main builder clean and focused.
///
/// OpenRouter is an OpenAI-compatible provider that offers access to multiple AI models
/// through a unified API, with additional features like web search capabilities.
class OpenRouterBuilder {
  final LLMBuilder _baseBuilder;

  OpenRouterBuilder(this._baseBuilder);

  // ========== OpenRouter-specific configuration methods ==========

  /// Configures web search for OpenRouter models
  ///
  /// OpenRouter supports web search in two ways:
  /// 1. Simple: Add `:online` to model name
  /// 2. Advanced: Use web plugin with custom parameters
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openRouter((openrouter) => openrouter
  ///         .webSearch(
  ///           maxResults: 5,
  ///           searchPrompt: 'Focus on recent developments',
  ///         ))
  ///     .apiKey(apiKey)
  ///     .model('anthropic/claude-3.5-sonnet')
  ///     .build();
  /// ```
  OpenRouterBuilder webSearch({
    int maxResults = 5,
    String? searchPrompt,
    bool useOnlineShortcut = true,
  }) {
    _baseBuilder.extension(
        LLMConfigKeys.webSearchConfig,
        WebSearchConfig.openRouter(
          maxResults: maxResults,
          searchPrompt: searchPrompt,
          useOnlineShortcut: useOnlineShortcut,
        ));
    return this;
  }

  /// Sets a custom search prompt for web search
  ///
  /// This prompt guides the search behavior and helps focus on specific
  /// types of information or sources.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openRouter((openrouter) => openrouter
  ///         .searchPrompt('Focus on recent academic papers and research'))
  ///     .apiKey(apiKey)
  ///     .build();
  /// ```
  OpenRouterBuilder searchPrompt(String prompt) {
    _baseBuilder.extension(LLMConfigKeys.searchPrompt, prompt);
    return this;
  }

  /// Enables or disables the online shortcut feature
  ///
  /// When enabled, you can simply add `:online` to the model name
  /// to enable web search without additional configuration.
  ///
  /// Example:
  /// ```dart
  /// // With online shortcut enabled (default)
  /// final provider = await ai()
  ///     .openRouter((openrouter) => openrouter
  ///         .useOnlineShortcut(true))
  ///     .apiKey(apiKey)
  ///     .model('anthropic/claude-3.5-sonnet:online')
  ///     .build();
  /// ```
  OpenRouterBuilder useOnlineShortcut(bool enabled) {
    _baseBuilder.extension(LLMConfigKeys.useOnlineShortcut, enabled);
    return this;
  }

  /// Sets the maximum number of search results to include
  ///
  /// Controls how many search results are included in the context
  /// when performing web searches.
  ///
  /// Range: 1-20 (recommended: 3-10)
  OpenRouterBuilder maxSearchResults(int maxResults) {
    _baseBuilder.extension(LLMConfigKeys.maxSearchResults, maxResults);
    return this;
  }

  // ========== Convenience methods for common configurations ==========

  /// Configure for academic research with focused search
  ///
  /// Optimizes settings for academic and research queries with
  /// appropriate search prompts and result limits.
  OpenRouterBuilder forAcademicResearch() {
    return webSearch(
      maxResults: 8,
      searchPrompt:
          'Focus on academic papers, research publications, and scholarly sources',
      useOnlineShortcut: false,
    );
  }

  /// Configure for news and current events
  ///
  /// Optimizes settings for news queries and current events with
  /// recent information focus.
  OpenRouterBuilder forNewsAndEvents() {
    return webSearch(
      maxResults: 10,
      searchPrompt:
          'Focus on recent news, current events, and up-to-date information',
      useOnlineShortcut: true,
    );
  }

  /// Configure for technical documentation and coding
  ///
  /// Optimizes settings for technical queries, documentation,
  /// and programming-related searches.
  OpenRouterBuilder forTechnicalQueries() {
    return webSearch(
      maxResults: 6,
      searchPrompt:
          'Focus on technical documentation, official docs, and programming resources',
      useOnlineShortcut: false,
    );
  }

  /// Configure for general web search
  ///
  /// Balanced settings for general-purpose web searches with
  /// moderate result limits and no specific search focus.
  OpenRouterBuilder forGeneralSearch() {
    return webSearch(
      maxResults: 5,
      searchPrompt: null, // No specific prompt
      useOnlineShortcut: true,
    );
  }

  /// Configure for quick searches with online shortcut
  ///
  /// Minimal configuration that relies on the `:online` model suffix
  /// for simple web search activation.
  OpenRouterBuilder forQuickSearch() {
    return useOnlineShortcut(true);
  }

  // ========== Build methods ==========

  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with ModelListingCapability
  ///
  /// OpenRouter provides access to multiple models from different providers,
  /// making model listing particularly useful for discovering available options.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }
}
