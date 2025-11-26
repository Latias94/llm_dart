import '../core/registry.dart';
import '../models/tool_models.dart';
import '../models/chat_models.dart';
import '../models/audio_models.dart';
import '../models/image_models.dart';
import '../models/file_models.dart';
import '../models/moderation_models.dart';
import '../models/assistant_models.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' show OpenAIProvider;
import '../providers/google/builder.dart';
import '../providers/google/tts.dart';
import '../providers/openai/builder.dart';
import '../providers/anthropic/builder.dart';
import '../providers/ollama/builder.dart';
import '../providers/elevenlabs/builder.dart';
import '../providers/openai/compatible/openrouter/builder.dart';
import 'http_config.dart';
import '../utils/message_resolver.dart';

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
    _providerId = providerId;

    // Get default config for this provider if it's registered
    final factory = LLMProviderRegistry.getFactory(providerId);
    if (factory != null) {
      _config = factory.getDefaultConfig();
    }

    return this;
  }

  /// Convenience methods for built-in providers
  LLMBuilder openai([OpenAIBuilder Function(OpenAIBuilder)? configure]) {
    provider('openai');
    if (configure != null) {
      final openaiBuilder = OpenAIBuilder(this);
      configure(openaiBuilder);
    }
    return this;
  }

  LLMBuilder anthropic(
      [AnthropicBuilder Function(AnthropicBuilder)? configure]) {
    provider('anthropic');
    if (configure != null) {
      final anthropicBuilder = AnthropicBuilder(this);
      configure(anthropicBuilder);
    }
    return this;
  }

  LLMBuilder google([GoogleLLMBuilder Function(GoogleLLMBuilder)? configure]) {
    provider('google');
    if (configure != null) {
      final googleBuilder = GoogleLLMBuilder(this);
      configure(googleBuilder);
    }
    return this;
  }

  LLMBuilder deepseek() => provider('deepseek');

  LLMBuilder ollama([OllamaBuilder Function(OllamaBuilder)? configure]) {
    provider('ollama');
    if (configure != null) {
      final ollamaBuilder = OllamaBuilder(this);
      configure(ollamaBuilder);
    }
    return this;
  }

  LLMBuilder xai() => provider('xai');
  LLMBuilder phind() => provider('phind');
  LLMBuilder groq() => provider('groq');

  LLMBuilder elevenlabs(
      [ElevenLabsBuilder Function(ElevenLabsBuilder)? configure]) {
    provider('elevenlabs');
    if (configure != null) {
      final elevenLabsBuilder = ElevenLabsBuilder(this);
      configure(elevenLabsBuilder);
    }
    return this;
  }

  /// Convenience methods for OpenAI-compatible providers
  /// These use the OpenAI interface but with provider-specific configurations
  LLMBuilder deepseekOpenAI() => provider('deepseek-openai');
  LLMBuilder googleOpenAI() => provider('google-openai');
  LLMBuilder xaiOpenAI() => provider('xai-openai');
  LLMBuilder groqOpenAI() => provider('groq-openai');
  LLMBuilder phindOpenAI() => provider('phind-openai');
  LLMBuilder openRouter(
      [OpenRouterBuilder Function(OpenRouterBuilder)? configure]) {
    provider('openrouter');
    if (configure != null) {
      final openRouterBuilder = OpenRouterBuilder(this);
      configure(openRouterBuilder);
    }
    return this;
  }

  LLMBuilder githubCopilot() => provider('github-copilot');
  LLMBuilder togetherAI() => provider('together-ai');

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

  /// Sets voice for text-to-speech (OpenAI providers)
  LLMBuilder voice(String voiceName) {
    _config = _config.withExtension(LLMConfigKeys.voice, voiceName);
    return this;
  }

  /// Enables reasoning/thinking for supported providers (Anthropic, OpenAI o1, Ollama)
  LLMBuilder reasoning(bool enable) {
    _config = _config.withExtension(LLMConfigKeys.reasoning, enable);
    return this;
  }

  /// Sets thinking budget tokens for Anthropic extended thinking
  LLMBuilder thinkingBudgetTokens(int tokens) {
    _config = _config.withExtension(LLMConfigKeys.thinkingBudgetTokens, tokens);
    return this;
  }

  /// Enables interleaved thinking for Anthropic (Claude 4 models only)
  LLMBuilder interleavedThinking(bool enable) {
    _config = _config.withExtension(LLMConfigKeys.interleavedThinking, enable);
    return this;
  }

  /// Sets provider-specific extension
  LLMBuilder extension(String key, dynamic value) {
    _config = _config.withExtension(key, value);
    return this;
  }

  /// Gets the current configuration (for internal use by builders)
  LLMConfig get currentConfig => _config;

  /// Configure HTTP settings using a fluent builder
  ///
  /// This method provides a clean, organized way to configure HTTP settings
  /// without cluttering the main LLMBuilder interface.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .http((http) => http
  ///         .proxy('http://proxy.company.com:8080')
  ///         .headers({'X-Custom-Header': 'value'})
  ///         .connectionTimeout(Duration(seconds: 30))
  ///         .enableLogging(true))
  ///     .build();
  /// ```
  LLMBuilder http(HttpConfig Function(HttpConfig) configure) {
    final httpConfig = HttpConfig();
    final configuredHttp = configure(httpConfig);
    final httpSettings = configuredHttp.build();

    // Apply all HTTP settings as extensions
    for (final entry in httpSettings.entries) {
      _config = _config.withExtension(entry.key, entry.value);
    }

    return this;
  }

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
    return extension('webSearchConfig', config);
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

  /// Image generation configuration methods
  LLMBuilder imageSize(String size) => extension(LLMConfigKeys.imageSize, size);
  LLMBuilder batchSize(int size) => extension(LLMConfigKeys.batchSize, size);
  LLMBuilder imageSeed(String seed) => extension(LLMConfigKeys.imageSeed, seed);
  LLMBuilder numInferenceSteps(int steps) =>
      extension(LLMConfigKeys.numInferenceSteps, steps);
  LLMBuilder guidanceScale(double scale) =>
      extension(LLMConfigKeys.guidanceScale, scale);
  LLMBuilder promptEnhancement(bool enabled) =>
      extension(LLMConfigKeys.promptEnhancement, enabled);

  /// Audio configuration methods
  LLMBuilder audioFormat(String format) =>
      extension(LLMConfigKeys.audioFormat, format);
  LLMBuilder audioQuality(String quality) =>
      extension(LLMConfigKeys.audioQuality, quality);
  LLMBuilder sampleRate(int rate) => extension(LLMConfigKeys.sampleRate, rate);
  LLMBuilder languageCode(String code) =>
      extension(LLMConfigKeys.languageCode, code);

  /// Advanced audio configuration methods
  LLMBuilder audioProcessingMode(String mode) =>
      extension(LLMConfigKeys.audioProcessingMode, mode);
  LLMBuilder includeTimestamps(bool enabled) =>
      extension(LLMConfigKeys.includeTimestamps, enabled);
  LLMBuilder timestampGranularity(String granularity) =>
      extension(LLMConfigKeys.timestampGranularity, granularity);
  LLMBuilder textNormalization(String mode) =>
      extension(LLMConfigKeys.textNormalization, mode);
  LLMBuilder instructions(String instructions) =>
      extension(LLMConfigKeys.instructions, instructions);
  LLMBuilder previousText(String text) =>
      extension(LLMConfigKeys.previousText, text);
  LLMBuilder nextText(String text) => extension(LLMConfigKeys.nextText, text);
  LLMBuilder audioSeed(int seed) => extension(LLMConfigKeys.audioSeed, seed);
  LLMBuilder enableLogging(bool enabled) =>
      extension(LLMConfigKeys.enableLogging, enabled);
  LLMBuilder optimizeStreamingLatency(int level) =>
      extension(LLMConfigKeys.optimizeStreamingLatency, level);

  /// STT-specific configuration methods
  LLMBuilder diarize(bool enabled) => extension(LLMConfigKeys.diarize, enabled);
  LLMBuilder numSpeakers(int count) =>
      extension(LLMConfigKeys.numSpeakers, count);
  LLMBuilder tagAudioEvents(bool enabled) =>
      extension(LLMConfigKeys.tagAudioEvents, enabled);
  LLMBuilder webhook(bool enabled) => extension(LLMConfigKeys.webhook, enabled);
  LLMBuilder prompt(String prompt) => extension(LLMConfigKeys.prompt, prompt);
  LLMBuilder responseFormat(String format) =>
      extension(LLMConfigKeys.responseFormat, format);
  LLMBuilder cloudStorageUrl(String url) =>
      extension(LLMConfigKeys.cloudStorageUrl, url);

  // =======================================================================
  // High-level text generation helpers (generateText / streamText)
  //
  // These helpers provide a Vercel AI SDK-style experience on top of the
  // core ChatCapability interface, while remaining fully provider-agnostic.
  // =======================================================================

  /// Generate a single text response using the current builder configuration.
  ///
  /// This is a convenience wrapper around [ChatCapability.chat] that:
  /// - Resolves the input into a list of [ChatMessage] instances.
  /// - Calls the provider's `chat(...)` method.
  /// - Returns a [GenerateTextResult] with text, thinking, tool calls,
  ///   usage, warnings, and call metadata.
  ///
  /// You must provide exactly one of:
  /// - [prompt]: simple single-turn user message
  /// - [messages]: full conversation history
  /// - [structuredPrompt]: a structured [ChatPromptMessage] built via
  ///   [ChatPromptBuilder].
  Future<GenerateTextResult> generateText({
    String? prompt,
    List<ChatMessage>? messages,
    ChatPromptMessage? structuredPrompt,
    CancellationToken? cancelToken,
  }) async {
    final provider = await build();
    final resolvedMessages = resolveMessagesForTextGeneration(
      prompt: prompt,
      messages: messages,
      structuredPrompt: structuredPrompt,
    );

    final response = await provider.chat(
      resolvedMessages,
      cancelToken: cancelToken,
    );

    return GenerateTextResult(
      rawResponse: response,
      text: response.text,
      thinking: response.thinking,
      toolCalls: response.toolCalls,
      usage: response.usage,
      warnings: response.warnings,
      metadata: response.callMetadata,
    );
  }

  /// Stream a text response using the current builder configuration.
  ///
  /// This is a convenience wrapper around [ChatCapability.chatStream] that:
  /// - Resolves the input into a list of [ChatMessage] instances.
  /// - Builds the provider and forwards the stream of [ChatStreamEvent]
  ///   objects (thinking deltas, text deltas, tool call deltas, completion).
  ///
  /// The input resolution rules are the same as [generateText].
  Stream<ChatStreamEvent> streamText({
    String? prompt,
    List<ChatMessage>? messages,
    ChatPromptMessage? structuredPrompt,
    CancellationToken? cancelToken,
  }) async* {
    final provider = await build();
    final resolvedMessages = resolveMessagesForTextGeneration(
      prompt: prompt,
      messages: messages,
      structuredPrompt: structuredPrompt,
    );

    yield* provider.chatStream(
      resolvedMessages,
      cancelToken: cancelToken,
    );
  }

  /// Stream high-level text parts using the current builder configuration.
  ///
  /// This is similar to [streamText] but adapts the low-level
  /// [ChatStreamEvent] stream into a provider-agnostic sequence of
  /// [StreamTextPart] values (text start/delta/end, thinking deltas,
  /// tool input lifecycle events, and a final completion part).
  Stream<StreamTextPart> streamTextParts({
    String? prompt,
    List<ChatMessage>? messages,
    ChatPromptMessage? structuredPrompt,
    CancellationToken? cancelToken,
  }) async* {
    final rawStream = streamText(
      prompt: prompt,
      messages: messages,
      structuredPrompt: structuredPrompt,
      cancelToken: cancelToken,
    );

    yield* adaptStreamText(rawStream);
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
  Future<LanguageModel> buildLanguageModel() async {
    final provider = await build();
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
  // These methods provide type-safe access to specific capabilities
  // at build time, eliminating the need for runtime type casting.

  /// Builds a provider with AudioCapability
  ///
  /// Returns a provider that implements AudioCapability for text-to-speech,
  /// speech-to-text, and other audio processing features.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support audio capabilities.
  ///
  /// Example:
  /// ```dart
  /// final audioProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .buildAudio();
  ///
  /// // Direct usage without type casting
  /// final voices = await audioProvider.getVoices();
  /// ```
  Future<AudioCapability> buildAudio() async {
    final provider = await build();
    if (provider is! AudioCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support audio capabilities. '
        'Supported providers: OpenAI, ElevenLabs',
      );
    }
    return provider as AudioCapability;
  }

  /// Builds a provider with ImageGenerationCapability
  ///
  /// Returns a provider that implements ImageGenerationCapability for
  /// generating, editing, and creating variations of images.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support image generation.
  ///
  /// Example:
  /// ```dart
  /// final imageProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .model('dall-e-3')
  ///     .buildImageGeneration();
  ///
  /// // Direct usage without type casting
  /// final images = await imageProvider.generateImage(prompt: 'A sunset');
  /// ```
  Future<ImageGenerationCapability> buildImageGeneration() async {
    final provider = await build();
    if (provider is! ImageGenerationCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support image generation capabilities. '
        'Supported providers: OpenAI (DALL-E)',
      );
    }
    return provider as ImageGenerationCapability;
  }

  /// Builds a provider with EmbeddingCapability
  ///
  /// Returns a provider that implements EmbeddingCapability for
  /// generating vector embeddings from text.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support embeddings.
  ///
  /// Example:
  /// ```dart
  /// final embeddingProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .model('text-embedding-3-small')
  ///     .buildEmbedding();
  ///
  /// // Direct usage without type casting
  /// final embeddings = await embeddingProvider.embed(['Hello world']);
  /// ```
  Future<EmbeddingCapability> buildEmbedding() async {
    final provider = await build();
    if (provider is! EmbeddingCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support embedding capabilities. '
        'Supported providers: OpenAI, Google, DeepSeek',
      );
    }
    return provider as EmbeddingCapability;
  }

  /// Builds a provider with embedding middlewares applied.
  ///
  /// This method wraps the underlying provider in a lightweight
  /// proxy that:
  /// - Executes the registered [EmbeddingMiddleware] chain for
  ///   `embed` calls.
  /// - Delegates all other capabilities directly to the underlying provider.
  ///
  /// The returned instance is suitable for applications that want
  /// cross-cutting concerns (logging, caching, policy enforcement)
  /// around embedding calls without changing the default behavior
  /// of [buildEmbedding].
  Future<EmbeddingCapability> buildEmbeddingWithMiddleware() async {
    final provider = await build();
    if (provider is! EmbeddingCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support embedding capabilities. '
        'Supported providers: OpenAI, Google, DeepSeek',
      );
    }

    if (_embeddingMiddlewares.isEmpty) {
      return provider as EmbeddingCapability;
    }

    return _EmbeddingMiddlewareWrappedProvider(
      provider as EmbeddingCapability,
      _providerId ?? 'unknown',
      _config,
      List<EmbeddingMiddleware>.from(_embeddingMiddlewares),
    );
  }

  /// Builds a provider with FileManagementCapability
  ///
  /// Returns a provider that implements FileManagementCapability for
  /// uploading, managing, and processing files.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support file management.
  ///
  /// Example:
  /// ```dart
  /// final fileProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .buildFileManagement();
  ///
  /// // Direct usage without type casting
  /// final file = await fileProvider.uploadFile('document.pdf');
  /// ```
  Future<FileManagementCapability> buildFileManagement() async {
    final provider = await build();
    if (provider is! FileManagementCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support file management capabilities. '
        'Supported providers: OpenAI, Anthropic',
      );
    }
    return provider as FileManagementCapability;
  }

  /// Builds a provider with ModerationCapability
  ///
  /// Returns a provider that implements ModerationCapability for
  /// content moderation and safety checks.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support moderation.
  ///
  /// Example:
  /// ```dart
  /// final moderationProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .buildModeration();
  ///
  /// // Direct usage without type casting
  /// final result = await moderationProvider.moderate('Some text to check');
  /// ```
  Future<ModerationCapability> buildModeration() async {
    final provider = await build();
    if (provider is! ModerationCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support moderation capabilities. '
        'Supported providers: OpenAI',
      );
    }
    return provider as ModerationCapability;
  }

  /// Builds a provider with AssistantCapability
  ///
  /// Returns a provider that implements AssistantCapability for
  /// creating and managing AI assistants.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support assistants.
  ///
  /// Example:
  /// ```dart
  /// final assistantProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .buildAssistant();
  ///
  /// // Direct usage without type casting
  /// final assistant = await assistantProvider.createAssistant(request);
  /// ```
  Future<AssistantCapability> buildAssistant() async {
    final provider = await build();
    if (provider is! AssistantCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support assistant capabilities. '
        'Supported providers: OpenAI',
      );
    }
    return provider as AssistantCapability;
  }

  /// Builds a provider with chat middlewares applied and
  /// AssistantCapability support.
  ///
  /// This is a convenience method for applications that want
  /// to use assistants with middleware-wrapped chat calls.
  Future<AssistantCapability> buildAssistantWithMiddleware() async {
    final provider = await buildWithMiddleware();
    if (provider is! AssistantCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support assistant capabilities. '
        'Supported providers: OpenAI',
      );
    }
    return provider as AssistantCapability;
  }

  /// Builds a provider with ModelListingCapability
  ///
  /// Returns a provider that implements ModelListingCapability for
  /// discovering available models.
  ///
  /// Throws [UnsupportedCapabilityError] if the provider doesn't support model listing.
  ///
  /// Example:
  /// ```dart
  /// final modelProvider = await ai()
  ///     .openai()
  ///     .apiKey(apiKey)
  ///     .buildModelListing();
  ///
  /// // Direct usage without type casting
  /// final models = await modelProvider.listModels();
  /// ```
  Future<ModelListingCapability> buildModelListing() async {
    final provider = await build();
    if (provider is! ModelListingCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support model listing capabilities. '
        'Supported providers: OpenAI, Anthropic, DeepSeek, Ollama',
      );
    }
    return provider as ModelListingCapability;
  }

  /// Builds an OpenAI provider with Responses API enabled
  ///
  /// This is a convenience method that automatically:
  /// - Ensures the provider is OpenAI
  /// - Enables the Responses API (`useResponsesAPI(true)`)
  /// - Returns a properly typed OpenAIProvider with Responses API access
  /// - Ensures the `openaiResponses` capability is available
  ///
  /// Throws [UnsupportedCapabilityError] if the provider is not OpenAI.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai
  ///         .webSearchTool()
  ///         .fileSearchTool(vectorStoreIds: ['vs_123']))
  ///     .apiKey(apiKey)
  ///     .model('gpt-4o')
  ///     .buildOpenAIResponses();
  ///
  /// // Direct access to Responses API without casting
  /// final responsesAPI = provider.responses!;
  /// final response = await responsesAPI.chat(messages);
  /// ```
  ///
  /// **Note**: This method automatically enables Responses API even if not
  /// explicitly called with `useResponsesAPI()`. The returned provider will
  /// always support `LLMCapability.openaiResponses`.
  Future<OpenAIProvider> buildOpenAIResponses() async {
    if (_providerId != 'openai') {
      throw UnsupportedCapabilityError(
        'buildOpenAIResponses() can only be used with OpenAI provider. '
        'Current provider: $_providerId. Use .openai() first.',
      );
    }

    // Automatically enable Responses API if not already enabled
    final isResponsesAPIEnabled =
        _config.getExtension<bool>(LLMConfigKeys.useResponsesAPI) ?? false;
    if (!isResponsesAPIEnabled) {
      extension(LLMConfigKeys.useResponsesAPI, true);
    }

    final provider = await build();

    // Cast to OpenAI provider (safe since we checked provider ID)
    final openaiProvider = provider as OpenAIProvider;

    // Verify that Responses API is properly initialized
    if (openaiProvider.responses == null) {
      throw StateError('OpenAI Responses API not properly initialized. '
          'This should not happen when using buildOpenAIResponses().');
    }

    return openaiProvider;
  }

  /// Builds a Google provider with TTS capability
  ///
  /// This is a convenience method that automatically:
  /// - Ensures the provider is Google
  /// - Sets a TTS-compatible model if not already set
  /// - Returns a properly typed GoogleTTSCapability
  /// - Ensures the TTS functionality is available
  ///
  /// Throws [UnsupportedCapabilityError] if the provider is not Google or doesn't support TTS.
  ///
  /// Example:
  /// ```dart
  /// final ttsProvider = await ai()
  ///     .google((google) => google
  ///         .ttsModel('gemini-2.5-flash-preview-tts')
  ///         .enableAudioOutput())
  ///     .apiKey(apiKey)
  ///     .buildGoogleTTS();
  ///
  /// // Direct usage without type casting
  /// final response = await ttsProvider.generateSpeech(request);
  /// ```
  ///
  /// **Note**: This method automatically sets a TTS model if none is specified.
  Future<GoogleTTSCapability> buildGoogleTTS() async {
    if (_providerId != 'google') {
      throw UnsupportedCapabilityError(
        'buildGoogleTTS() can only be used with Google provider. '
        'Current provider: $_providerId. Use .google() first.',
      );
    }

    // Set default TTS model if none specified
    if (_config.model.isEmpty || !_config.model.contains('tts')) {
      model('gemini-2.5-flash-preview-tts');
    }

    final provider = await build();

    // Cast to Google TTS capability (safe since we checked provider ID)
    if (provider is! GoogleTTSCapability) {
      throw UnsupportedCapabilityError(
        'Google provider does not support TTS capabilities. '
        'Make sure you are using a TTS-compatible model.',
      );
    }

    return provider as GoogleTTSCapability;
  }
}

/// Internal wrapper that applies chat middlewares while delegating
/// all other capabilities to the underlying provider.
class _MiddlewareWrappedProvider extends BaseAudioCapability
    implements
        ChatCapability,
        EmbeddingCapability,
        ImageGenerationCapability,
        ModelListingCapability,
        FileManagementCapability,
        ModerationCapability,
        AssistantCapability,
        ProviderCapabilities {
  final ChatCapability _chat;
  final dynamic _inner;
  final String _providerId;
  final LLMConfig _config;
  final List<ChatMiddleware> _middlewares;

  _MiddlewareWrappedProvider(
    ChatCapability inner,
    this._providerId,
    this._config,
    List<ChatMiddleware> middlewares,
  )   : _chat = inner,
        _inner = inner,
        _middlewares = middlewares;
  Future<ChatResponse> _executeChatWithMiddlewares(
    ChatCallContext context,
  ) async {
    // Apply transform chain (if any)
    var ctx = context;
    for (final middleware in _middlewares) {
      final transform = middleware.transform;
      if (transform != null) {
        ctx = await transform(ctx);
      }
    }

    // Base chat function
    var next = (ChatCallContext c) => _chat.chatWithTools(
          c.messages,
          c.tools,
          cancelToken: c.cancelToken,
        );

    // Wrap chat in reverse order
    for (final middleware in _middlewares.reversed) {
      final wrap = middleware.wrapChat;
      if (wrap != null) {
        final currentNext = next;
        next = (c) => wrap(currentNext, c);
      }
    }

    return next(ctx);
  }

  Stream<ChatStreamEvent> _executeStreamWithMiddlewares(
    ChatCallContext context,
  ) async* {
    // Apply transform chain (if any)
    var ctx = context;
    for (final middleware in _middlewares) {
      final transform = middleware.transform;
      if (transform != null) {
        ctx = await transform(ctx);
      }
    }

    // Base stream function
    var next = (ChatCallContext c) => _chat.chatStream(
          c.messages,
          tools: c.tools,
          cancelToken: c.cancelToken,
        );

    // Wrap stream in reverse order
    for (final middleware in _middlewares.reversed) {
      final wrap = middleware.wrapStream;
      if (wrap != null) {
        final currentNext = next;
        next = (c) => wrap(currentNext, c);
      }
    }

    yield* next(ctx);
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    CancellationToken? cancelToken,
  }) {
    final context = ChatCallContext(
      providerId: _providerId,
      model: _config.model,
      config: _config,
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      operationKind: ChatOperationKind.chat,
    );
    return _executeChatWithMiddlewares(context);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    CancellationToken? cancelToken,
  }) {
    final context = ChatCallContext(
      providerId: _providerId,
      model: _config.model,
      config: _config,
      messages: messages,
      tools: tools,
      cancelToken: cancelToken,
      operationKind: ChatOperationKind.stream,
    );
    return _executeStreamWithMiddlewares(context);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() => _chat.memoryContents();

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) =>
      _chat.summarizeHistory(messages);

  // === AudioCapability delegation ===

  @override
  Set<AudioFeature> get supportedFeatures {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.supportedFeatures;
    }
    return const <AudioFeature>{};
  }

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.textToSpeech(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Text-to-speech not supported by provider $_providerId',
    );
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.textToSpeechStream(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Streaming text-to-speech not supported by provider $_providerId',
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.getVoices();
    }
    throw UnsupportedError(
        'Voice listing not supported by provider $_providerId');
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.speechToText(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Speech-to-text not supported by provider $_providerId',
    );
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.translateAudio(request, cancelToken: cancelToken);
    }
    throw UnsupportedError(
      'Audio translation not supported by provider $_providerId',
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.getSupportedLanguages();
    }
    throw UnsupportedError(
      'Language listing not supported by provider $_providerId',
    );
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.startRealtimeSession(config);
    }
    throw UnsupportedError(
      'Real-time audio not supported by provider $_providerId',
    );
  }

  @override
  List<String> getSupportedAudioFormats() {
    final inner = _inner;
    if (inner is AudioCapability) {
      return inner.getSupportedAudioFormats();
    }
    return const ['mp3', 'wav', 'ogg'];
  }

  // === EmbeddingCapability delegation ===

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    final inner = _inner;
    if (inner is EmbeddingCapability) {
      return inner.embed(input, cancelToken: cancelToken);
    }
    throw UnsupportedError('Embeddings not supported by provider $_providerId');
  }

  // === ImageGenerationCapability delegation ===

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.generateImages(request);
    }
    throw UnsupportedError(
        'Image generation not supported by provider $_providerId');
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.editImage(request);
    }
    throw UnsupportedError(
        'Image editing not supported by provider $_providerId');
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.createVariation(request);
    }
    throw UnsupportedError(
      'Image variation not supported by provider $_providerId',
    );
  }

  @override
  List<String> getSupportedSizes() {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.getSupportedSizes();
    }
    return const <String>[];
  }

  @override
  List<String> getSupportedFormats() {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.getSupportedFormats();
    }
    return const <String>[];
  }

  @override
  bool get supportsImageEditing {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.supportsImageEditing;
    }
    return false;
  }

  @override
  bool get supportsImageVariations {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.supportsImageVariations;
    }
    return false;
  }

  @override
  Future<List<String>> generateImage({
    required String prompt,
    String? model,
    String? negativePrompt,
    String? imageSize,
    int? batchSize,
    String? seed,
    int? numInferenceSteps,
    double? guidanceScale,
    bool? promptEnhancement,
  }) {
    final inner = _inner;
    if (inner is ImageGenerationCapability) {
      return inner.generateImage(
        prompt: prompt,
        model: model,
        negativePrompt: negativePrompt,
        imageSize: imageSize,
        batchSize: batchSize,
        seed: seed,
        numInferenceSteps: numInferenceSteps,
        guidanceScale: guidanceScale,
        promptEnhancement: promptEnhancement,
      );
    }
    throw UnsupportedError(
        'Image generation not supported by provider $_providerId');
  }

  // === ModelListingCapability delegation ===

  @override
  Future<List<AIModel>> models({CancellationToken? cancelToken}) {
    final inner = _inner;
    if (inner is ModelListingCapability) {
      return inner.models(cancelToken: cancelToken);
    }
    throw UnsupportedError(
        'Model listing not supported by provider $_providerId');
  }

  // === FileManagementCapability delegation ===

  @override
  Future<FileObject> uploadFile(FileUploadRequest request) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.uploadFile(request);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.listFiles(query);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<FileObject> retrieveFile(String fileId) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.retrieveFile(fileId);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<FileDeleteResponse> deleteFile(String fileId) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.deleteFile(fileId);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  @override
  Future<List<int>> getFileContent(String fileId) {
    final inner = _inner;
    if (inner is FileManagementCapability) {
      return inner.getFileContent(fileId);
    }
    throw UnsupportedError(
        'File management not supported by provider $_providerId');
  }

  // === ModerationCapability delegation ===

  @override
  Future<ModerationResponse> moderate(ModerationRequest request) {
    final inner = _inner;
    if (inner is ModerationCapability) {
      return inner.moderate(request);
    }
    throw UnsupportedError('Moderation not supported by provider $_providerId');
  }

  // === AssistantCapability delegation ===

  @override
  Future<Assistant> createAssistant(CreateAssistantRequest request) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.createAssistant(request);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<Assistant> retrieveAssistant(String assistantId) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.retrieveAssistant(assistantId);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<Assistant> modifyAssistant(
    String assistantId,
    ModifyAssistantRequest request,
  ) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.modifyAssistant(assistantId, request);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<ListAssistantsResponse> listAssistants([ListAssistantsQuery? query]) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.listAssistants(query);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  @override
  Future<DeleteAssistantResponse> deleteAssistant(String assistantId) {
    final inner = _inner;
    if (inner is AssistantCapability) {
      return inner.deleteAssistant(assistantId);
    }
    throw UnsupportedError('Assistants not supported by provider $_providerId');
  }

  // === ProviderCapabilities delegation ===

  @override
  Set<LLMCapability> get supportedCapabilities {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supportedCapabilities;
    }
    return const {LLMCapability.chat, LLMCapability.streaming};
  }

  @override
  bool supports(LLMCapability capability) {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supports(capability);
    }
    return capability == LLMCapability.chat ||
        capability == LLMCapability.streaming;
  }
}

/// Internal wrapper that applies embedding middlewares while delegating
/// all other capabilities to the underlying provider.
class _EmbeddingMiddlewareWrappedProvider
    implements EmbeddingCapability, ProviderCapabilities {
  final EmbeddingCapability _embedding;
  final dynamic _inner;
  final String _providerId;
  final LLMConfig _config;
  final List<EmbeddingMiddleware> _middlewares;

  _EmbeddingMiddlewareWrappedProvider(
    EmbeddingCapability inner,
    this._providerId,
    this._config,
    List<EmbeddingMiddleware> middlewares,
  )   : _embedding = inner,
        _inner = inner,
        _middlewares = middlewares;

  Future<List<List<double>>> _executeEmbedWithMiddlewares(
    EmbeddingCallContext context,
  ) async {
    var ctx = context;
    for (final middleware in _middlewares) {
      final transform = middleware.transform;
      if (transform != null) {
        ctx = await transform(ctx);
      }
    }

    var next = (EmbeddingCallContext c) =>
        _embedding.embed(c.input, cancelToken: c.cancelToken);

    for (final middleware in _middlewares.reversed) {
      final wrap = middleware.wrapEmbed;
      if (wrap != null) {
        final currentNext = next;
        next = (c) => wrap(currentNext, c);
      }
    }

    return next(ctx);
  }

  @override
  Future<List<List<double>>> embed(
    List<String> input, {
    CancellationToken? cancelToken,
  }) {
    final context = EmbeddingCallContext(
      providerId: _providerId,
      model: _config.model,
      config: _config,
      input: input,
      cancelToken: cancelToken,
    );
    return _executeEmbedWithMiddlewares(context);
  }

  @override
  Set<LLMCapability> get supportedCapabilities {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supportedCapabilities;
    }
    return const {LLMCapability.embedding};
  }

  @override
  bool supports(LLMCapability capability) {
    final inner = _inner;
    if (inner is ProviderCapabilities) {
      return inner.supports(capability);
    }
    return capability == LLMCapability.embedding;
  }
}
