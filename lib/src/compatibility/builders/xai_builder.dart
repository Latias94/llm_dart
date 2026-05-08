import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../models/tool_models.dart';
import '../../../providers/xai/config.dart';
import '../config/legacy_config_keys.dart';
import 'legacy_builder_provider_options.dart';

/// xAI-specific legacy builder DSL layered on top of [LLMBuilder].
class XAIBuilder {
  final LLMBuilder _baseBuilder;
  final LegacyBuilderProviderOptionWriter _providerOptions;

  XAIBuilder(LLMBuilder baseBuilder)
      : _baseBuilder = baseBuilder,
        _providerOptions = LegacyBuilderProviderOptionWriter.xai(baseBuilder);

  /// Enables or disables xAI Live Search.
  XAIBuilder liveSearch(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.xaiLiveSearch, enabled);
    return this;
  }

  /// Sets xAI Live Search parameters.
  XAIBuilder searchParameters(SearchParameters parameters) {
    _providerOptions.set(LegacyExtensionKeys.xaiSearchParameters, parameters);
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
    _providerOptions.set(LegacyExtensionKeys.jsonSchema, schema);
    return this;
  }

  /// Sets embedding encoding format.
  XAIBuilder embeddingEncodingFormat(String format) {
    _providerOptions.set(LegacyExtensionKeys.embeddingEncodingFormat, format);
    return this;
  }

  /// Sets embedding dimensions.
  XAIBuilder embeddingDimensions(int dimensions) {
    _providerOptions.set(LegacyExtensionKeys.embeddingDimensions, dimensions);
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
}
