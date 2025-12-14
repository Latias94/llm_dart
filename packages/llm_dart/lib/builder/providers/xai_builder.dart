import '../llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart'
    show SearchParameters, XAIConfigKeys;

/// xAI-specific LLM builder with provider-specific configuration methods.
///
/// This builder provides a layered configuration approach where xAI-specific
/// parameters (live search, search parameters, etc.) are handled separately
/// from the generic [LLMBuilder], keeping the main builder clean and focused.
///
/// Use this for xAI-specific parameters only. For common parameters like
/// [LLMBuilder.apiKey], [LLMBuilder.model], [LLMBuilder.temperature], etc.,
/// continue using the base [LLMBuilder] methods.
class XAIBuilder {
  final LLMBuilder _baseBuilder;

  XAIBuilder(this._baseBuilder);

  /// Enables or disables Live Search for xAI (Grok) models.
  ///
  /// When enabled, Grok can access real-time information from the web using
  /// xAI's live search capabilities.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///   .xai((xai) => xai.liveSearch())
  ///   .apiKey(apiKey)
  ///   .model('grok-3')
  ///   .build();
  /// ```
  XAIBuilder liveSearch([bool enable = true]) {
    _baseBuilder.extension(LLMConfigKeys.webSearchEnabled, enable);
    return this;
  }

  /// Configures Live Search using xAI-native [SearchParameters].
  ///
  /// This helper writes the given [parameters] into [XAIConfigKeys.searchParameters].
  /// The xAI provider then maps these settings to its HTTP API via
  /// [XAIConfig.fromLLMConfig].
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///   .xai((xai) => xai.searchParameters(
  ///     SearchParameters.webSearch(
  ///       maxResults: 5,
  ///       excludedWebsites: ['example.com'],
  ///     ),
  ///   ))
  ///   .apiKey(apiKey)
  ///   .model('grok-3')
  ///   .build();
  /// ```
  XAIBuilder searchParameters(SearchParameters parameters) {
    _baseBuilder.extension(XAIConfigKeys.searchParameters, parameters);
    return this;
  }

  /// High-level helper to configure simple web search for xAI using a
  /// [WebSearchConfig] abstraction.
  ///
  /// This method:
  /// - Marks web search as enabled via [LLMConfigKeys.webSearchEnabled].
  /// - Stores a [WebSearchConfig] in [LLMConfigKeys.webSearchConfig].
  ///
  /// The xAI provider then derives [SearchParameters] from this config in
  /// [XAIConfig.fromLLMConfig], enabling Grok to perform Live Search.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///   .xai((xai) => xai.webSearch(
  ///     maxResults: 5,
  ///     blockedDomains: ['example.com'],
  ///   ))
  ///   .apiKey(apiKey)
  ///   .model('grok-3')
  ///   .build();
  /// ```
  XAIBuilder webSearch({
    int? maxResults,
    List<String>? blockedDomains,
    List<String>? allowedDomains,
    WebSearchLocation? location,
    String mode = 'auto',
    String? fromDate,
    String? toDate,
  }) {
    final config = WebSearchConfig(
      maxResults: maxResults,
      blockedDomains: blockedDomains,
      allowedDomains: allowedDomains,
      location: location,
      mode: mode,
      fromDate: fromDate,
      toDate: toDate,
      searchType: WebSearchType.web,
    );

    _baseBuilder
      ..enableWebSearch()
      ..extension(LLMConfigKeys.webSearchConfig, config);

    return this;
  }

  /// Convenience helper for news-focused web search with xAI.
  ///
  /// This configures [WebSearchConfig] with [WebSearchType.news] so that the
  /// xAI provider can derive appropriate [SearchParameters] for news sources.
  XAIBuilder newsSearch({
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? blockedDomains,
    WebSearchLocation? location,
    String mode = 'auto',
  }) {
    final config = WebSearchConfig(
      maxResults: maxResults,
      blockedDomains: blockedDomains,
      location: location,
      mode: mode,
      fromDate: fromDate,
      toDate: toDate,
      searchType: WebSearchType.news,
    );

    _baseBuilder
      ..enableWebSearch()
      ..extension(LLMConfigKeys.webSearchConfig, config);

    return this;
  }

  // ========== Build methods ==========

  /// Builds and returns a configured xAI chat provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with [EmbeddingCapability] for xAI embeddings.
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }
}
