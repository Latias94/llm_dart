import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../models/tool_models.dart';
import '../../../providers/xai/config.dart';
import '../config/legacy_config_keys.dart';
import '../config/legacy_provider_options.dart';

/// xAI-specific legacy builder DSL layered on top of [LLMBuilder].
class XAIBuilder {
  final LLMBuilder _baseBuilder;

  XAIBuilder(this._baseBuilder);

  /// Enables or disables xAI Live Search.
  XAIBuilder liveSearch(bool enabled) {
    _setProviderOption(LegacyExtensionKeys.xaiLiveSearch, enabled);
    return this;
  }

  /// Sets xAI Live Search parameters.
  XAIBuilder searchParameters(SearchParameters parameters) {
    _setProviderOption(LegacyExtensionKeys.xaiSearchParameters, parameters);
    return this;
  }

  /// Configures web search parameters.
  XAIBuilder webSearch({
    String mode = 'auto',
    int? maxResults,
    List<String>? excludedWebsites,
  }) {
    return searchParameters(
      SearchParameters.webSearch(
        mode: mode,
        maxResults: maxResults,
        excludedWebsites: excludedWebsites,
      ),
    );
  }

  /// Configures news search parameters.
  XAIBuilder newsSearch({
    String mode = 'auto',
    int? maxResults,
    String? fromDate,
    String? toDate,
    List<String>? excludedWebsites,
  }) {
    return searchParameters(
      SearchParameters.newsSearch(
        mode: mode,
        maxResults: maxResults,
        fromDate: fromDate,
        toDate: toDate,
        excludedWebsites: excludedWebsites,
      ),
    );
  }

  /// Sets structured output schema for xAI chat requests.
  XAIBuilder jsonSchema(StructuredOutputFormat schema) {
    _setProviderOption(LegacyExtensionKeys.jsonSchema, schema);
    return this;
  }

  /// Sets embedding encoding format.
  XAIBuilder embeddingEncodingFormat(String format) {
    _setProviderOption(LegacyExtensionKeys.embeddingEncodingFormat, format);
    return this;
  }

  /// Sets embedding dimensions.
  XAIBuilder embeddingDimensions(int dimensions) {
    _setProviderOption(LegacyExtensionKeys.embeddingDimensions, dimensions);
    return this;
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with EmbeddingCapability.
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  void _setProviderOption(String key, dynamic value) {
    setLegacyBuilderProviderOption(
      _baseBuilder,
      LegacyProviderOptionNamespaces.xai,
      key,
      value,
    );
  }
}
