import '../../../../builder/llm_builder.dart';
import '../../../../core/capability.dart';
import '../../../../models/tool_models.dart';
import '../../../../src/compatibility/config/legacy_config_keys.dart';
import '../../../../src/compatibility/config/legacy_provider_options.dart';

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
    setLegacyBuilderProviderOption(
      _baseBuilder,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.webSearchEnabled,
      true,
    );
    return this;
  }

  /// Sets structured output schema for OpenRouter chat requests.
  OpenRouterBuilder jsonSchema(StructuredOutputFormat schema) {
    setLegacyBuilderProviderOption(
      _baseBuilder,
      LegacyProviderOptionNamespaces.openrouter,
      LegacyExtensionKeys.jsonSchema,
      schema,
    );
    return this;
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
