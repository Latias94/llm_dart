import 'package:llm_dart_core/llm_dart_core.dart';

import 'http_config.dart';
import 'provider_config.dart';

/// Builder for configuring and instantiating LLM providers
///
/// Provides a fluent interface for setting various configuration
/// options like model selection, API keys, generation parameters, etc.
///
/// The new version uses the provider registry system for extensibility.
class LLMBuilder {
  /// Selected provider ID (replaces backend enum)
  String? _providerId;

  /// Provider options collected before a provider is selected.
  ///
  /// This preserves the older "order doesn't matter" ergonomics without
  /// relying on any global unscoped "extensions" map.
  final Map<String, dynamic> _pendingSelectedProviderOptions = {};

  /// Unified configuration being built
  LLMConfig _config = LLMConfig(
    baseUrl: '',
    model: '',
  );

  /// Creates a new empty builder instance with default values
  LLMBuilder();

  /// The currently selected provider ID, if any.
  String? get providerId => _providerId;

  /// Gets the current configuration (for internal use by builders)
  LLMConfig get currentConfig => _config;

  /// Sets the provider to use (new registry-based approach)
  LLMBuilder provider(String providerId) {
    final previousProviderId = _providerId;
    final previousConfig = _config;

    _providerId = providerId;

    // Get default config for this provider if it's registered
    final factory = LLMProviderRegistry.getFactory(providerId);
    if (factory != null) {
      final defaultConfig = factory.getDefaultConfig();

      // Preserve configuration that was set before selecting a provider for the
      // first time. If the builder is switching from one provider to another,
      // keep the original behavior: reset to provider defaults.
      if (previousProviderId == null) {
        final mergedProviderOptions = <String, Map<String, dynamic>>{
          ...defaultConfig.providerOptions,
        };

        for (final entry in previousConfig.providerOptions.entries) {
          mergedProviderOptions[entry.key] = {
            ...?mergedProviderOptions[entry.key],
            ...entry.value,
          };
        }

        _config = defaultConfig.copyWith(
          apiKey: previousConfig.apiKey,
          baseUrl: previousConfig.baseUrl.isNotEmpty
              ? previousConfig.baseUrl
              : defaultConfig.baseUrl,
          model: previousConfig.model.isNotEmpty
              ? previousConfig.model
              : defaultConfig.model,
          maxTokens: previousConfig.maxTokens,
          temperature: previousConfig.temperature,
          systemPrompt: previousConfig.systemPrompt,
          timeout: previousConfig.timeout,
          topP: previousConfig.topP,
          topK: previousConfig.topK,
          tools: previousConfig.tools,
          providerTools: previousConfig.providerTools,
          toolChoice: previousConfig.toolChoice,
          stopSequences: previousConfig.stopSequences,
          user: previousConfig.user,
          serviceTier: previousConfig.serviceTier,
          providerOptions: mergedProviderOptions,
        );
      } else {
        _config = defaultConfig;
      }
    }

    _flushPendingSelectedProviderOptions();
    return this;
  }

  void _flushPendingSelectedProviderOptions() {
    final providerId = _providerId;
    if (providerId == null || _pendingSelectedProviderOptions.isEmpty) return;

    _config = _config.withProviderOptions(
      providerId,
      Map<String, dynamic>.from(_pendingSelectedProviderOptions),
    );
    _pendingSelectedProviderOptions.clear();
  }

  LLMBuilder _setSelectedProviderOption(String key, dynamic value) {
    final providerId = _providerId;
    if (providerId == null) {
      _pendingSelectedProviderOptions[key] = value;
      return this;
    }
    return providerOption(providerId, key, value);
  }

  /// Sets the API key for authentication
  LLMBuilder apiKey(String key) {
    _config = _config.copyWith(apiKey: key);
    return this;
  }

  /// Set a provider-specific option in a namespaced structure.
  ///
  /// This is the preferred long-term mechanism for provider-only features.
  /// It avoids global key collisions by namespacing on `providerId`.
  LLMBuilder providerOption(String providerId, String key, dynamic value) {
    _config = _config.withProviderOption(providerId, key, value);
    return this;
  }

  /// Merge provider-specific options for a provider.
  LLMBuilder providerOptions(String providerId, Map<String, dynamic> options) {
    _config = _config.withProviderOptions(providerId, options);
    return this;
  }

  /// Set a provider-specific option for the currently selected provider.
  ///
  /// Throws if no provider has been selected yet.
  LLMBuilder option(String key, dynamic value) {
    final providerId = _providerId;
    if (providerId == null) {
      throw const GenericError('No provider specified');
    }
    return providerOption(providerId, key, value);
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

  /// Sets provider-native tools (provider-executed built-in tools).
  LLMBuilder providerTools(List<ProviderTool> providerTools) {
    _config = _config.copyWith(providerTools: providerTools);
    return this;
  }

  /// Adds a single provider-native tool (provider-executed built-in tool).
  LLMBuilder providerTool(ProviderTool providerTool) {
    final current = List<ProviderTool>.from(_config.providerTools ?? const []);
    current.add(providerTool);
    _config = _config.copyWith(providerTools: current);
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
  LLMBuilder reasoningEffort(ReasoningEffort? effort) {
    return _setSelectedProviderOption('reasoningEffort', effort?.value);
  }

  /// Sets structured output schema for JSON responses
  LLMBuilder jsonSchema(StructuredOutputFormat schema) {
    return _setSelectedProviderOption('jsonSchema', schema);
  }

  /// Sets voice for text-to-speech (OpenAI providers)
  LLMBuilder voice(String voiceName) {
    return _setSelectedProviderOption('voice', voiceName);
  }

  /// Enables reasoning/thinking for supported providers (Anthropic, OpenAI o1, Ollama)
  LLMBuilder reasoning(bool enable) {
    return _setSelectedProviderOption('reasoning', enable);
  }

  /// Sets thinking budget tokens for Anthropic extended thinking
  LLMBuilder thinkingBudgetTokens(int tokens) {
    return _setSelectedProviderOption('thinkingBudgetTokens', tokens);
  }

  /// Enables interleaved thinking for Anthropic (Claude 4 models only)
  LLMBuilder interleavedThinking(bool enable) {
    return _setSelectedProviderOption('interleavedThinking', enable);
  }

  /// Configure HTTP settings using a fluent builder
  LLMBuilder http(HttpConfig Function(HttpConfig) configure) {
    final httpConfig = HttpConfig();
    final configuredHttp = configure(httpConfig);
    final httpSettings = configuredHttp.build();

    // Transport-level configuration lives in `transportOptions`.
    _config = _config.withTransportOptions(httpSettings);

    return this;
  }

  /// Configure provider-specific options using a fluent builder.
  ///
  /// This is a convenience wrapper around `providerOptions(providerId, ...)`.
  /// It requires a provider to be selected first.
  LLMBuilder providerConfig(ProviderConfig Function(ProviderConfig) configure) {
    final providerId = _providerId;
    if (providerId == null) {
      throw const GenericError('No provider specified');
    }

    final config = ProviderConfig();
    final configured = configure(config);
    final options = configured.build();
    return providerOptions(providerId, options);
  }

  /// Convenience methods for common provider options
  LLMBuilder embeddingEncodingFormat(String format) {
    return _setSelectedProviderOption('embeddingEncodingFormat', format);
  }

  LLMBuilder embeddingDimensions(int dimensions) {
    return _setSelectedProviderOption('embeddingDimensions', dimensions);
  }

  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }

    return LLMProviderRegistry.createProvider(_providerId!, _config);
  }

  Future<Object> _buildAny() async {
    if (_providerId == null) {
      throw const GenericError('No provider specified');
    }
    return LLMProviderRegistry.createAnyProvider(_providerId!, _config);
  }

  // ========== Capability Factory Methods ==========
  Future<TextToSpeechCapability> buildSpeech() async {
    final provider = await _buildAny();
    if (provider is! TextToSpeechCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support text-to-speech capabilities.',
      );
    }
    return provider;
  }

  Future<StreamingTextToSpeechCapability> buildStreamingSpeech() async {
    final provider = await _buildAny();
    if (provider is! StreamingTextToSpeechCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support streaming text-to-speech capabilities.',
      );
    }
    return provider;
  }

  Future<SpeechToTextCapability> buildTranscription() async {
    final provider = await _buildAny();
    if (provider is! SpeechToTextCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support speech-to-text capabilities.',
      );
    }
    return provider;
  }

  Future<AudioTranslationCapability> buildAudioTranslation() async {
    final provider = await _buildAny();
    if (provider is! AudioTranslationCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support audio translation capabilities.',
      );
    }
    return provider;
  }

  Future<RealtimeAudioCapability> buildRealtimeAudio() async {
    final provider = await _buildAny();
    if (provider is! RealtimeAudioCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support realtime audio capabilities.',
      );
    }
    return provider;
  }

  Future<ImageGenerationCapability> buildImageGeneration() async {
    final provider = await _buildAny();
    if (provider is! ImageGenerationCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support image generation capabilities.',
      );
    }
    return provider;
  }

  Future<EmbeddingCapability> buildEmbedding() async {
    final provider = await _buildAny();
    if (provider is! EmbeddingCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support embedding capabilities.',
      );
    }
    return provider;
  }

  Future<RerankCapability> buildRerank() async {
    final provider = await _buildAny();
    if (provider is! RerankCapability) {
      throw UnsupportedCapabilityError(
        'Provider "$_providerId" does not support rerank capabilities.',
      );
    }
    return provider;
  }
}
