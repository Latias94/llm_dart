export '../src/compatibility/builders/llm_builder_provider_capability_extensions.dart'
    show LLMBuilderProviderCapabilityExtensions;
export '../src/compatibility/builders/llm_builder_provider_extensions.dart'
    show LLMBuilderProviderExtensions;

import '../core/capability.dart';
import '../core/config.dart';
import '../core/llm_error.dart';
import '../core/registry.dart';
import '../models/chat_models.dart';
import '../models/tool_models.dart';
import '../src/bootstrap/root_registry_bootstrap.dart';
import '../src/compatibility/compatibility_resolver.dart';
import '../src/compatibility/config/legacy_provider_options.dart';
import 'http_config.dart';

/// Builder for configuring and instantiating LLM providers
///
/// Provides a fluent interface for setting various configuration
/// options like model selection, API keys, generation parameters, and
/// compatibility-facing provider selection.
class LLMBuilder {
  /// Selected provider ID (replaces backend enum)
  String? _providerId;

  /// Unified configuration being built
  LLMConfig _config = LLMConfig(
    baseUrl: '',
    model: '',
  );

  /// Creates a new empty builder instance with default values
  LLMBuilder() {
    ensureRootRegistryBootstrap();
  }

  /// Sets the provider to use.
  LLMBuilder provider(String providerId) => _setProvider(providerId);

  /// Sets the API key for authentication.
  LLMBuilder apiKey(String key) => _setConfig(_config.copyWith(apiKey: key));

  /// Sets the base URL for API requests.
  LLMBuilder baseUrl(String url) {
    final normalizedUrl = url.endsWith('/') ? url : '$url/';
    return _setConfig(_config.copyWith(baseUrl: normalizedUrl));
  }

  /// Sets the model identifier to use.
  LLMBuilder model(String model) => _setConfig(_config.copyWith(model: model));

  /// Sets the maximum number of tokens to generate.
  LLMBuilder maxTokens(int tokens) =>
      _setConfig(_config.copyWith(maxTokens: tokens));

  /// Sets the temperature for controlling response randomness (0.0-1.0).
  LLMBuilder temperature(double temp) =>
      _setConfig(_config.copyWith(temperature: temp));

  /// Sets the system prompt/context.
  LLMBuilder systemPrompt(String prompt) =>
      _setConfig(_config.copyWith(systemPrompt: prompt));

  /// Sets the global timeout for all HTTP operations.
  LLMBuilder timeout(Duration timeout) =>
      _setConfig(_config.copyWith(timeout: timeout));

  /// Sets the top-p (nucleus) sampling parameter.
  LLMBuilder topP(double topP) => _setConfig(_config.copyWith(topP: topP));

  /// Sets the top-k sampling parameter.
  LLMBuilder topK(int topK) => _setConfig(_config.copyWith(topK: topK));

  /// Sets the function tools.
  LLMBuilder tools(List<Tool> tools) =>
      _setConfig(_config.copyWith(tools: tools));

  /// Sets the tool choice.
  LLMBuilder toolChoice(ToolChoice choice) =>
      _setConfig(_config.copyWith(toolChoice: choice));

  /// Sets stop sequences for generation.
  LLMBuilder stopSequences(List<String> sequences) =>
      _setConfig(_config.copyWith(stopSequences: sequences));

  /// Sets user identifier for tracking and analytics.
  LLMBuilder user(String userId) => _setConfig(_config.copyWith(user: userId));

  /// Sets service tier for API requests.
  LLMBuilder serviceTier(ServiceTier tier) =>
      _setConfig(_config.copyWith(serviceTier: tier));

  /// Gets the current configuration for compatibility builders.
  LLMConfig get currentConfig => _config;

  /// Gets the currently selected provider ID.
  String? get currentProviderId => _providerId;

  /// Configure HTTP settings using a fluent builder.
  LLMBuilder http(HttpConfig Function(HttpConfig) configure) {
    final httpConfig = HttpConfig();
    final configuredHttp = configure(httpConfig);
    final httpSettings = configuredHttp.build();
    return _applyHttpSettings(httpSettings);
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }

    final compatProvider = tryCreateCompatProvider(
      providerId: _providerId!,
      config: _config,
    );
    if (compatProvider != null) {
      return compatProvider;
    }

    return LLMProviderRegistry.createProvider(_providerId!, _config);
  }

  /// Builds a provider with AudioCapability.
  Future<AudioCapability> buildAudio() {
    return _buildCapability<AudioCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support audio capabilities. '
          'Supported providers: OpenAI, ElevenLabs',
    );
  }

  /// Builds a provider with ImageGenerationCapability.
  Future<ImageGenerationCapability> buildImageGeneration() {
    return _buildCapability<ImageGenerationCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support image generation capabilities. '
          'Supported providers: OpenAI (DALL-E)',
    );
  }

  /// Builds a provider with EmbeddingCapability.
  Future<EmbeddingCapability> buildEmbedding() {
    return _buildCapability<EmbeddingCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support embedding capabilities. '
          'Supported providers: OpenAI, Google, DeepSeek',
    );
  }

  /// Builds a provider with FileManagementCapability.
  Future<FileManagementCapability> buildFileManagement() {
    return _buildCapability<FileManagementCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support file management capabilities. '
          'Supported providers: OpenAI, Anthropic',
    );
  }

  /// Builds a provider with ModerationCapability.
  Future<ModerationCapability> buildModeration() {
    return _buildCapability<ModerationCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support moderation capabilities. '
          'Supported providers: OpenAI',
    );
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() {
    return _buildCapability<ModelListingCapability>(
      unsupportedMessage:
          'Provider "$_providerId" does not support model listing capabilities. '
          'Supported providers: OpenAI, Anthropic, DeepSeek, Ollama',
    );
  }

  LLMBuilder _setProvider(String providerId) {
    _providerId = providerId;

    final factory = LLMProviderRegistry.getFactory(providerId);
    if (factory != null) {
      _config = factory.getDefaultConfig();
    }

    return this;
  }

  LLMBuilder _setConfig(LLMConfig config) {
    _config = config;
    return this;
  }

  LLMBuilder _setExtension(String key, dynamic value) {
    _config = _config.withExtension(key, value);
    return this;
  }

  LLMBuilder _applyHttpSettings(Map<String, dynamic> settings) {
    for (final entry in settings.entries) {
      _config = _config.withExtension(entry.key, entry.value);
    }

    return this;
  }

  Future<T> _buildCapability<T extends Object>({
    required String unsupportedMessage,
  }) async {
    final provider = await build();
    if (provider is! T) {
      throw UnsupportedCapabilityError(unsupportedMessage);
    }

    return provider as T;
  }
}

/// Stores a legacy builder callback option under the provider-scoped
/// `providerOptions` compatibility bag.
///
/// This is intentionally narrower than arbitrary root extension mutation: it
/// keeps compatibility builder callbacks provider-owned while the old root
/// shortcut surface is being removed.
void setLegacyBuilderProviderOption(
  LLMBuilder builder,
  String namespace,
  String key,
  dynamic value,
) {
  final providerOptions = setLegacyProviderOption(
    builder.currentConfig,
    namespace,
    key,
    value,
  );

  builder._setExtension(legacyProviderOptionsBagKey, providerOptions);
}
