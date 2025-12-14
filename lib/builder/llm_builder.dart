// Prompt-first LLM builder. This is the primary entry point for configuring
// providers and producing ChatCapability / LanguageModel instances.

import 'dart:math' as math;

import 'package:llm_dart_core/llm_dart_core.dart';
import '../src/builtin_providers.dart';
import 'http_config.dart';

part 'llm_builder_http_extensions.dart';
part 'llm_builder_image_extensions.dart';
part 'llm_builder_audio_extensions.dart';
part 'llm_builder_search_extensions.dart';
part 'llm_builder_reranking_adapter.dart';
part 'llm_builder_chat_middleware_wrapper.dart';
part 'llm_builder_text_helpers.dart';
part 'llm_builder_capabilities.dart';

/// Builder for configuring and instantiating LLM providers
///
/// Provides a fluent interface for setting various configuration
/// options like model selection, API keys, generation parameters, etc.
///
/// The new version uses the provider registry system for extensibility.
class LLMBuilder {
  /// Selected provider ID (replaces backend enum)
  String? _providerId;

  /// Unified configuration being built
  LLMConfig _config = LLMConfig(
    baseUrl: '',
    model: '',
  );

  /// Registered chat middlewares for this builder.
  ///
  /// These middlewares are applied only when using middleware-aware
  /// build methods (e.g. [buildWithMiddleware]) to keep the default
  /// build behavior fully backwards compatible.
  final List<ChatMiddleware> _middlewares = [];

  /// Registered embedding middlewares for this builder.
  ///
  /// These middlewares are applied only when using embedding-aware
  /// build methods (e.g. [buildEmbeddingWithMiddleware]) to keep the
  /// default build behavior fully backwards compatible.
  final List<EmbeddingMiddleware> _embeddingMiddlewares = [];

  /// Creates a new empty builder instance with default values
  LLMBuilder();

  /// Configure provider and model using a single model identifier.
  ///
  /// The [modelId] should be in the form `"provider:model"`, for example:
  /// - `"openai:gpt-4o"`
  /// - `"deepseek:deepseek-reasoner"`
  /// - `"ollama:llama3.2"`
  ///
  /// This mirrors the model-centric style of the Vercel AI SDK while
  /// reusing the existing provider registry under the hood.
  LLMBuilder use(String modelId) {
    final separatorIndex = modelId.indexOf(':');
    if (separatorIndex <= 0 || separatorIndex == modelId.length - 1) {
      throw ArgumentError(
        'Model identifier must be in the form "provider:model", e.g. "openai:gpt-4o". '
        'Received: "$modelId".',
      );
    }

    final providerId = modelId.substring(0, separatorIndex);
    final model = modelId.substring(separatorIndex + 1);

    provider(providerId);
    this.model(model);

    return this;
  }

  /// Sets the provider to use (new registry-based approach)
  LLMBuilder provider(String providerId) {
    // Ensure built-in providers are registered before resolving defaults.
    // This mirrors the previous behavior where providers were registered
    // lazily on first use by the registry itself.
    registerBuiltinProviders();

    final previous = _config;
    _providerId = providerId;

    // Get default config for this provider if it's registered
    final factory = LLMProviderRegistry.getFactory(providerId);
    if (factory != null) {
      _mergeWithDefaults(factory.getDefaultConfig());
    } else {
      _config = previous;
    }

    return this;
  }

  /// Merge provider defaults into the current config without overwriting
  /// values the caller has already set (apiKey, baseUrl, model, extensions, etc.).
  void _mergeWithDefaults(LLMConfig defaults) {
    _config = LLMConfig(
      apiKey: _config.apiKey ?? defaults.apiKey,
      baseUrl: _config.baseUrl.isNotEmpty ? _config.baseUrl : defaults.baseUrl,
      model: _config.model.isNotEmpty ? _config.model : defaults.model,
      maxTokens: _config.maxTokens ?? defaults.maxTokens,
      temperature: _config.temperature ?? defaults.temperature,
      systemPrompt: _config.systemPrompt ?? defaults.systemPrompt,
      timeout: _config.timeout ?? defaults.timeout,
      topP: _config.topP ?? defaults.topP,
      topK: _config.topK ?? defaults.topK,
      tools: _config.tools ?? defaults.tools,
      toolChoice: _config.toolChoice ?? defaults.toolChoice,
      stopSequences: _config.stopSequences ?? defaults.stopSequences,
      user: _config.user ?? defaults.user,
      serviceTier: _config.serviceTier ?? defaults.serviceTier,
      extensions: {
        ...defaults.extensions,
        ..._config.extensions,
      },
    );
  }

  /// Ensure that the current provider supports chat/text capabilities.
  ///
  /// This is used by high-level text helpers (generateText/streamText/etc.)
  /// to fail fast for providers that are intentionally audio-only, such as
  /// ElevenLabs. Audio-centric providers remain fully usable via the
  /// capability factory methods (e.g. [buildAudio]) and audio helpers.
  void _ensureChatCapable(String operation) {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }

    final providerId = _providerId!;

    // Use the registry's capability information to determine whether
    // the selected provider can handle chat/text operations.
    if (!LLMProviderRegistry.supportsCapability(
      providerId,
      LLMCapability.chat,
    )) {
      final buffer = StringBuffer()
        ..write('Provider "$providerId" does not support $operation. ');

      if (providerId == 'elevenlabs') {
        buffer
          ..write('ElevenLabs specializes in audio capabilities. ')
          ..write(
            'Use buildAudio(), generateSpeech(), transcribe(), or '
            'transcribeFile() instead.',
          );
      } else {
        buffer.write(
          'Check the provider documentation for supported capabilities.',
        );
      }

      throw UnsupportedCapabilityError(buffer.toString());
    }
  }

  /// Replaces the current middleware list with the given middlewares.
  ///
  /// This is conceptually similar to the `middleware`/`middlewares`
  /// option in the Vercel AI SDK: callers provide the complete
  /// middleware configuration for this builder.
  LLMBuilder middlewares(List<ChatMiddleware> middlewares) {
    _middlewares
      ..clear()
      ..addAll(middlewares);
    return this;
  }

  /// Adds a single middleware to the end of the middleware list.
  ///
  /// This is a convenience method for incremental configuration.
  LLMBuilder addMiddleware(ChatMiddleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  /// Clears all configured middlewares.
  LLMBuilder clearMiddlewares() {
    _middlewares.clear();
    return this;
  }

  /// Replaces the current embedding middleware list with the given middlewares.
  LLMBuilder embeddingMiddlewares(List<EmbeddingMiddleware> middlewares) {
    _embeddingMiddlewares
      ..clear()
      ..addAll(middlewares);
    return this;
  }

  /// Adds a single embedding middleware to the end of the middleware list.
  LLMBuilder addEmbeddingMiddleware(EmbeddingMiddleware middleware) {
    _embeddingMiddlewares.add(middleware);
    return this;
  }

  /// Clears all configured embedding middlewares.
  LLMBuilder clearEmbeddingMiddlewares() {
    _embeddingMiddlewares.clear();
    return this;
  }

  /// Sets the API key for authentication
  LLMBuilder apiKey(String key) {
    _config = _config.copyWith(apiKey: key);
    return this;
  }

  /// Sets the base URL for API requests
  LLMBuilder baseUrl(String url) {
    // Ensure the URL ends with a slash
    final normalizedUrl = url.endsWith('/') ? url : '$url/';
    _config = _config.copyWith(baseUrl: normalizedUrl);
    return this;
  }

  /// Sets the model identifier to use
  LLMBuilder model(String model) {
    _config = _config.copyWith(model: model);
    return this;
  }

  /// Sets the maximum number of tokens to generate
  LLMBuilder maxTokens(int tokens) {
    _config = _config.copyWith(maxTokens: tokens);
    return this;
  }

  /// Sets the temperature for controlling response randomness (0.0-1.0)
  LLMBuilder temperature(double temp) {
    _config = _config.copyWith(temperature: temp);
    return this;
  }

  /// Sets the system prompt/context
  LLMBuilder systemPrompt(String prompt) {
    _config = _config.copyWith(systemPrompt: prompt);
    return this;
  }

  /// Sets the global timeout for all HTTP operations
  ///
  /// This method sets a global timeout that serves as the default for all
  /// HTTP timeout types (connection, receive, send). Individual HTTP timeout
  /// configurations will override this global setting.
  ///
  /// **Priority order:**
  /// 1. HTTP-specific timeouts (highest priority)
  /// 2. Global timeout set by this method (medium priority)
  /// 3. Provider defaults (lowest priority)
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .timeout(Duration(minutes: 2))     // Global default: 2 minutes
  ///     .http((http) => http
  ///         .receiveTimeout(Duration(minutes: 5))) // Override receive: 5 minutes
  ///     .build();
  /// // Result: connection=2min, receive=5min, send=2min
  /// ```
  ///
  /// For setting all HTTP timeouts to the same value, use:
  /// ```dart
  /// .http((http) => http
  ///     .connectionTimeout(Duration(seconds: 30))
  ///     .receiveTimeout(Duration(minutes: 5))
  ///     .sendTimeout(Duration(seconds: 60)))
  /// ```
  LLMBuilder timeout(Duration timeout) {
    _config = _config.copyWith(timeout: timeout);
    return this;
  }

  /// Sets the top-p (nucleus) sampling parameter
  LLMBuilder topP(double topP) {
    _config = _config.copyWith(topP: topP);
    return this;
  }

  /// Sets the top-k sampling parameter
  LLMBuilder topK(int topK) {
    _config = _config.copyWith(topK: topK);
    return this;
  }

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0).
  ///
  /// This mirrors the OpenAI-style `frequency_penalty` parameter and is
  /// consumed by providers that support it (OpenAI, Google, DeepSeek,
  /// OpenAI‑compatible profiles, etc.).
  LLMBuilder frequencyPenalty(double penalty) {
    _config = _config.withExtension(LLMConfigKeys.frequencyPenalty, penalty);
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0).
  ///
  /// This mirrors the OpenAI-style `presence_penalty` parameter and is
  /// consumed by providers that support it (OpenAI, Google, DeepSeek,
  /// OpenAI‑compatible profiles, etc.).
  LLMBuilder presencePenalty(double penalty) {
    _config = _config.withExtension(LLMConfigKeys.presencePenalty, penalty);
    return this;
  }

  /// Sets a random seed for deterministic sampling (when supported).
  ///
  /// Providers that support deterministic runs (e.g. OpenAI, Google,
  /// some OpenAI‑compatible backends) will use this value to make
  /// repeated calls with the same configuration return identical
  /// results as far as possible.
  LLMBuilder seed(int seedValue) {
    _config = _config.withExtension(LLMConfigKeys.seed, seedValue);
    return this;
  }

  /// Sets the function tools
  LLMBuilder tools(List<Tool> tools) {
    _config = _config.copyWith(tools: tools);
    return this;
  }

  /// Sets the tool choice
  LLMBuilder toolChoice(ToolChoice choice) {
    _config = _config.copyWith(toolChoice: choice);
    return this;
  }

  /// Sets stop sequences for generation
  LLMBuilder stopSequences(List<String> sequences) {
    _config = _config.copyWith(stopSequences: sequences);
    return this;
  }

  /// Sets user identifier for tracking and analytics
  LLMBuilder user(String userId) {
    _config = _config.copyWith(user: userId);
    return this;
  }

  /// Sets service tier for API requests
  LLMBuilder serviceTier(ServiceTier tier) {
    _config = _config.copyWith(serviceTier: tier);
    return this;
  }

  /// Sets the reasoning effort for models that support it (e.g., OpenAI o1, Gemini)
  /// Valid values: ReasoningEffort.low, ReasoningEffort.medium, ReasoningEffort.high, or null to disable
  LLMBuilder reasoningEffort(ReasoningEffort? effort) {
    _config =
        _config.withExtension(LLMConfigKeys.reasoningEffort, effort?.value);
    return this;
  }

  /// Sets structured output schema for JSON responses
  LLMBuilder jsonSchema(StructuredOutputFormat schema) {
    _config = _config.withExtension(LLMConfigKeys.jsonSchema, schema);
    return this;
  }

  /// Enables reasoning/thinking for supported providers (Anthropic, OpenAI o1, Ollama)
  LLMBuilder reasoning(bool enable) {
    _config = _config.withExtension(LLMConfigKeys.reasoning, enable);
    return this;
  }

  /// Sets provider-specific extension
  LLMBuilder extension(String key, dynamic value) {
    _config = _config.withExtension(key, value);
    return this;
  }

  /// Gets the current configuration (for internal use by builders)
  LLMConfig get currentConfig => _config;

  /// Convenience methods for common extensions
  LLMBuilder embeddingEncodingFormat(String format) =>
      extension(LLMConfigKeys.embeddingEncodingFormat, format);
  LLMBuilder embeddingDimensions(int dimensions) =>
      extension(LLMConfigKeys.embeddingDimensions, dimensions);

  /// Web Search configuration methods
  ///
  /// These methods provide a unified interface for configuring web search
  /// across different providers (xAI, Anthropic, etc.). The implementation
  /// details are handled automatically based on the selected provider.

  /// Enables web search functionality
  ///
  /// This is a universal method that works across all providers that support
  /// web search. The underlying implementation varies by provider:
  /// - **xAI**: Uses Live Search with search_parameters
  /// - **Anthropic**: Uses web_search tool
  /// - **Others**: Provider-specific implementations
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .xai()  // or .anthropic(), etc.
  ///     .apiKey(apiKey)
  ///     .enableWebSearch()
  ///     .build();
  /// ```
  LLMBuilder enableWebSearch() =>
      extension(LLMConfigKeys.webSearchEnabled, true);

  /// Configures web search with detailed options
  ///
  /// This method provides fine-grained control over web search behavior
  /// using a unified configuration that adapts to each provider's API.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .anthropic()
  ///     .apiKey(apiKey)
  ///     .webSearch(
  ///       maxUses: 3,
  ///       allowedDomains: ['wikipedia.org', 'github.com'],
  ///       location: WebSearchLocation.sanFrancisco(),
  ///     )
  ///     .build();
  /// ```
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
      location: location,
      mode: mode,
      fromDate: fromDate,
      toDate: toDate,
    );
    return extension(LLMConfigKeys.webSearchConfig, config);
  }

  /// Quick web search setup with basic options
  ///
  /// A simplified method for common web search scenarios.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .xai()
  ///     .apiKey(apiKey)
  ///     .quickWebSearch(maxResults: 5)
  ///     .build();
  /// ```
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
  ///
  /// Configures the provider to search news sources specifically.
  /// This is particularly useful for current events and recent information.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .xai()
  ///     .apiKey(apiKey)
  ///     .newsSearch(
  ///       maxResults: 10,
  ///       fromDate: '2024-01-01',
  ///     )
  ///     .build();
  /// ```
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
      mode: 'auto',
      searchType: WebSearchType.news,
    );
    return extension(LLMConfigKeys.webSearchConfig, config);
  }

  /// Configures search location for localized results
  ///
  /// This method sets the geographic context for search results,
  /// which can improve relevance for location-specific queries.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .anthropic()
  ///     .apiKey(apiKey)
  ///     .enableWebSearch()
  ///     .searchLocation(WebSearchLocation.newYork())
  ///     .build();
  /// ```
  LLMBuilder searchLocation(WebSearchLocation location) {
    return extension(LLMConfigKeys.webSearchLocation, location);
  }

  /// Advanced web search configuration with full control
  ///
  /// This method provides access to all web search parameters and allows
  /// fine-grained control over the search behavior across all providers.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .anthropic()
  ///     .apiKey(apiKey)
  ///     .advancedWebSearch(
  ///       strategy: WebSearchStrategy.tool,
  ///       contextSize: WebSearchContextSize.high,
  ///       searchPrompt: 'Focus on academic sources',
  ///       maxUses: 3,
  ///       allowedDomains: ['arxiv.org', 'scholar.google.com'],
  ///     )
  ///     .build();
  /// ```
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
    double? dynamicThreshold,
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
      location: location,
      mode: mode,
      dynamicThreshold: dynamicThreshold,
      fromDate: fromDate,
      toDate: toDate,
      searchType: searchType,
    );
    return extension(LLMConfigKeys.webSearchConfig, config);
  }

  /// Builds and returns a configured LLM provider instance
  ///
  /// Returns a unified ChatCapability interface that can be used consistently
  /// across different LLM providers. The actual implementation will vary based
  /// on the selected provider.
  ///
  /// Note: Some providers may implement additional interfaces like EmbeddingCapability,
  /// ModelListingCapability, etc. Use dynamic casting to access these features.
  ///
  /// Throws [LLMError] if:
  /// - No provider is specified
  /// - Provider is not registered
  /// - Required configuration like API keys are missing
  Future<ChatCapability> build() async {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }

    // Ensure the selected provider exposes chat capabilities before
    // going through the registry. This fails fast for audio-only
    // providers such as ElevenLabs.
    _ensureChatCapable('chat capabilities');

    // Use the registry to create the provider
    return LLMProviderRegistry.createProvider(_providerId!, _config);
  }

  /// Builds a high-level [LanguageModel] wrapper for this builder.
  ///
  /// This method adapts the underlying [ChatCapability] to the
  /// provider-agnostic [LanguageModel] interface, which is conceptually
  /// aligned with the Vercel AI SDK's language model abstraction.
  ///
  /// This is useful when you want to:
  /// - Keep a stable reference to a configured model
  /// - Pass the model into helper functions that operate on [LanguageModel]
  /// - Decouple higher-level logic from concrete provider types
  ///
  /// If chat middlewares are configured on this builder, they will be applied
  /// to the underlying [ChatCapability] used by the returned [LanguageModel].
  Future<LanguageModel> buildLanguageModel() async {
    _ensureChatCapable('LanguageModel building');

    final provider = await buildWithMiddleware();
    final providerId = _providerId ?? 'unknown';
    final modelId = _config.model;

    return DefaultLanguageModel(
      providerId: providerId,
      modelId: modelId,
      config: _config,
      chat: provider,
    );
  }

  /// Builds a provider with chat middlewares applied.
  ///
  /// This method wraps the underlying provider in a lightweight
  /// proxy that:
  /// - Executes the registered [ChatMiddleware] chain for
  ///   `chat` / `chatWithTools` calls.
  /// - Delegates all other capabilities (audio, embeddings,
  ///   images, etc.) directly to the underlying provider.
  ///
  /// The returned instance is suitable for applications that want
  /// cross-cutting concerns around chat calls without changing
  /// the default behavior of [build] or capability-specific
  /// factory methods.
  Future<ChatCapability> buildWithMiddleware() async {
    _ensureChatCapable('chat with middleware');

    final baseProvider = await build();

    // If no middlewares are registered, return the underlying provider.
    if (_middlewares.isEmpty) {
      return baseProvider;
    }

    return _MiddlewareWrappedProvider(
      baseProvider,
      _providerId ?? 'unknown',
      _config,
      List<ChatMiddleware>.from(_middlewares),
    );
  }

  // ========== Capability Factory Methods ==========
  // See LLMBuilderCapabilities extension in llm_builder_capabilities.dart
  // for type-safe accessors to specific capabilities.
}
