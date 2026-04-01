import '../../../../builder/llm_builder.dart';
import '../../../../core/capability.dart';
import '../../../../core/web_search.dart';
import '../../../../src/config/legacy_config_keys.dart';

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

  /// Enables the audited OpenRouter online-model intent.
  ///
  /// This is the only OpenRouter search-shaped builder entry that maps cleanly
  /// to the refactored compatibility bridge without pretending that richer
  /// legacy search fields have a stable wire contract.
  OpenRouterBuilder onlineSearch() {
    _baseBuilder.extension(LegacyExtensionKeys.webSearchEnabled, true);
    return this;
  }

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
  @Deprecated(
    'OpenRouterBuilder.webSearch() is a legacy migration helper. '
    'Use onlineSearch() for legacy online intent, or the stable AI.openRouter(...).chatModel(..., settings: OpenRouterChatModelSettings(search: OpenRouterSearchOptions.onlineModel())) API.',
  )
  OpenRouterBuilder webSearch({
    int maxResults = 5,
    String? searchPrompt,
    bool useOnlineShortcut = true,
  }) {
    _baseBuilder.extension(
      LegacyExtensionKeys.webSearchConfig,
      WebSearchConfig.openRouter(
        maxResults: maxResults,
        searchPrompt: searchPrompt,
        useOnlineShortcut: useOnlineShortcut,
      ),
    );
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
  @Deprecated(
    'OpenRouterBuilder.searchPrompt() has no frozen OpenRouter wire contract. '
    'Use normal prompt shaping or the stable OpenRouter profile API instead.',
  )
  OpenRouterBuilder searchPrompt(String prompt) {
    _baseBuilder.extension(LegacyExtensionKeys.searchPrompt, prompt);
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
  @Deprecated(
    'OpenRouterBuilder.useOnlineShortcut() is legacy builder ergonomics only. '
    'Use onlineSearch() or an explicit :online model ID instead.',
  )
  OpenRouterBuilder useOnlineShortcut(bool enabled) {
    _baseBuilder.extension(LegacyExtensionKeys.useOnlineShortcut, enabled);
    return this;
  }

  /// Sets the maximum number of search results to include
  ///
  /// Controls how many search results are included in the context
  /// when performing web searches.
  ///
  /// Range: 1-20 (recommended: 3-10)
  @Deprecated(
    'OpenRouterBuilder.maxSearchResults() is not backed by a frozen OpenRouter wire contract. '
    'Use the stable OpenRouter profile API if a tested request contract lands later.',
  )
  OpenRouterBuilder maxSearchResults(int maxResults) {
    _baseBuilder.extension(LegacyExtensionKeys.maxSearchResults, maxResults);
    return this;
  }

  // ========== Convenience methods for common configurations ==========

  /// Configure for academic research with focused search
  ///
  /// Optimizes settings for academic and research queries with
  /// appropriate search prompts and result limits.
  @Deprecated(
    'OpenRouterBuilder.forAcademicResearch() depends on legacy-only searchPrompt/maxSearchResults semantics. '
    'Prefer onlineSearch() plus normal prompt shaping.',
  )
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
  @Deprecated(
    'OpenRouterBuilder.forNewsAndEvents() depends on legacy-only searchPrompt/maxSearchResults semantics. '
    'Prefer onlineSearch() plus normal prompt shaping.',
  )
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
  @Deprecated(
    'OpenRouterBuilder.forTechnicalQueries() depends on legacy-only searchPrompt/maxSearchResults semantics. '
    'Prefer onlineSearch() plus normal prompt shaping.',
  )
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
  @Deprecated(
    'OpenRouterBuilder.forGeneralSearch() depends on legacy-only OpenRouter search helpers. '
    'Prefer onlineSearch() instead.',
  )
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
  @Deprecated(
    'OpenRouterBuilder.forQuickSearch() is legacy builder ergonomics only. '
    'Prefer onlineSearch() or an explicit :online model ID.',
  )
  OpenRouterBuilder forQuickSearch() {
    return onlineSearch();
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
