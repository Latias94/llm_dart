/// xAI-specific extension keys used in `LLMConfig.extensions`.
abstract final class XAIConfigKeys {
  /// Raw xAI `search_parameters` configuration (xAI native API).
  ///
  /// Stored as a structured [SearchParameters] instance.
  static const String searchParameters = 'searchParameters';
}
