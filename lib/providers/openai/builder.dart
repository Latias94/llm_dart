import '../../builder/llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_impl;
import 'builtin_tools.dart';

/// OpenAI-specific LLM builder with provider-specific configuration methods
///
/// This builder provides a layered configuration approach where OpenAI-specific
/// parameters are handled separately from the generic LLMBuilder, keeping the
/// main builder clean and focused.
///
/// Use this for OpenAI-specific parameters only. For common parameters like
/// apiKey, model, temperature, etc., continue using the base LLMBuilder methods.
class OpenAIBuilder {
  final LLMBuilder _baseBuilder;

  OpenAIBuilder(this._baseBuilder);

  // ========== OpenAI-specific configuration methods ==========

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0)
  ///
  /// Positive values penalize new tokens based on their existing frequency
  /// in the text so far, decreasing the model's likelihood to repeat the
  /// same line verbatim.
  ///
  /// - Negative values: Encourage repetition
  /// - 0.0: No penalty (default)
  /// - Positive values: Discourage repetition
  /// - Range: -2.0 to 2.0
  OpenAIBuilder frequencyPenalty(double penalty) {
    _baseBuilder.extension(LLMConfigKeys.frequencyPenalty, penalty);
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0)
  ///
  /// Positive values penalize new tokens based on whether they appear
  /// in the text so far, increasing the model's likelihood to talk about
  /// new topics.
  ///
  /// - Negative values: Encourage staying on topic
  /// - 0.0: No penalty (default)
  /// - Positive values: Encourage new topics
  /// - Range: -2.0 to 2.0
  OpenAIBuilder presencePenalty(double penalty) {
    _baseBuilder.extension(LLMConfigKeys.presencePenalty, penalty);
    return this;
  }

  /// Sets voice for text-to-speech models (e.g. OpenAI TTS voices).
  ///
  /// This is an OpenAI-specific voice name setting (e.g. `alloy`, `verse`).
  /// The value is passed via [LLMConfigKeys.voice] to the OpenAI audio module.
  OpenAIBuilder voice(String voiceName) {
    _baseBuilder.extension(LLMConfigKeys.voice, voiceName);
    return this;
  }

  /// Sets logit bias for specific tokens
  ///
  /// Modify the likelihood of specified tokens appearing in the completion.
  /// Maps tokens (specified by their token ID) to an associated bias value
  /// from -100 to 100.
  ///
  /// - -100: Token is banned
  /// - 0: No bias (default)
  /// - 100: Token is strongly encouraged
  OpenAIBuilder logitBias(Map<String, double> bias) {
    _baseBuilder.extension(LLMConfigKeys.logitBias, bias);
    return this;
  }

  /// Sets seed for deterministic outputs
  ///
  /// If specified, the system will make a best effort to sample
  /// deterministically, such that repeated requests with the same seed
  /// and parameters should return the same result.
  OpenAIBuilder seed(int seedValue) {
    _baseBuilder.extension(LLMConfigKeys.seed, seedValue);
    return this;
  }

  /// Enables or disables parallel tool calls
  ///
  /// Whether to enable parallel function calling during tool use.
  /// When enabled, the model can call multiple functions simultaneously.
  ///
  /// - true: Enable parallel tool calls (default for newer models)
  /// - false: Disable parallel tool calls (sequential execution)
  OpenAIBuilder parallelToolCalls(bool enabled) {
    _baseBuilder.extension(LLMConfigKeys.parallelToolCalls, enabled);
    return this;
  }

  /// Enables or disables log probabilities
  ///
  /// Whether to return log probabilities of the output tokens.
  /// If true, returns the log probabilities of each output token.
  OpenAIBuilder logprobs(bool enabled) {
    _baseBuilder.extension(LLMConfigKeys.logprobs, enabled);
    return this;
  }

  /// Sets the number of most likely tokens to return log probabilities for
  ///
  /// An integer between 0 and 20 specifying the number of most likely
  /// tokens to return at each token position, each with an associated
  /// log probability. logprobs must be set to true if this parameter is used.
  ///
  /// Range: 0-20
  OpenAIBuilder topLogprobs(int count) {
    _baseBuilder.extension(LLMConfigKeys.topLogprobs, count);
    return this;
  }

  /// Sets verbosity level for GPT-5 family models
  ///
  /// Controls how expansive the model's responses are:
  /// - `Verbosity.low`: Terse, minimal prose
  /// - `Verbosity.medium`: Balanced detail (default)
  /// - `Verbosity.high`: Verbose, great for audits, teaching, or hand-offs
  ///
  /// This parameter is specific to GPT-5 series models (gpt-5.1, gpt-5,
  /// gpt-5-mini, gpt-5-nano) and allows you to
  /// control output length and detail without changing your prompts.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai.verbosity(Verbosity.high))
  ///     .model('gpt-5.1') // Recommended GPT-5 family model
  ///     .build();
  /// ```
  OpenAIBuilder verbosity(Verbosity level) {
    _baseBuilder.extension(LLMConfigKeys.verbosity, level.value);
    return this;
  }

  // ========== OpenAI Responses API Configuration ==========

  /// Enables the new Responses API instead of Chat Completions API
  ///
  /// The Responses API combines the simplicity of Chat Completions with
  /// the tool-use capabilities of the Assistants API. It supports built-in
  /// tools like web search, file search, and computer use.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai
  ///         .useResponsesAPI()
  ///         .webSearchTool())
  ///     .apiKey(apiKey)
  ///     .model('gpt-5-mini')
  ///     .build();
  /// ```
  OpenAIBuilder useResponsesAPI([bool use = true]) {
    _baseBuilder.extension(LLMConfigKeys.useResponsesAPI, use);
    return this;
  }

  /// Sets previous response ID for chaining responses
  ///
  /// Used with Responses API to maintain context across multiple API calls.
  /// This allows for multi-turn conversations with state preservation.
  OpenAIBuilder previousResponseId(String responseId) {
    _baseBuilder.extension(LLMConfigKeys.previousResponseId, responseId);
    return this;
  }

  /// Adds web search built-in tool
  ///
  /// Enables the model to search the web for real-time information.
  /// Only available with Responses API.
  OpenAIBuilder webSearchTool({
    List<String>? allowedDomains,
    WebSearchContextSize? contextSize,
    WebSearchLocation? location,
  }) {
    final tools = _getBuiltInTools();
    tools.add(
      OpenAIBuiltInTools.webSearch(
        allowedDomains: allowedDomains,
        contextSize: contextSize,
        location: location,
      ),
    );
    _baseBuilder.extension(LLMConfigKeys.builtInTools, tools);
    return this;
  }

  /// Adds file search built-in tool
  ///
  /// Enables the model to search through documents in vector stores.
  /// Only available with Responses API.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai
  ///         .useResponsesAPI()
  ///         .fileSearchTool(vectorStoreIds: ['vs_123', 'vs_456']))
  ///     .build();
  /// ```
  OpenAIBuilder fileSearchTool({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) {
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.fileSearch(
      vectorStoreIds: vectorStoreIds,
      parameters: parameters,
    ));
    _baseBuilder.extension(LLMConfigKeys.builtInTools, tools);
    return this;
  }

  /// Adds computer use built-in tool
  ///
  /// Enables the model to interact with computers through mouse and keyboard actions.
  /// Currently in research preview with limited availability.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai
  ///         .useResponsesAPI()
  ///         .computerUseTool(
  ///           displayWidth: 1024,
  ///           displayHeight: 768,
  ///           environment: 'browser',
  ///         ))
  ///     .build();
  /// ```
  OpenAIBuilder computerUseTool({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) {
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.computerUse(
      displayWidth: displayWidth,
      displayHeight: displayHeight,
      environment: environment,
      parameters: parameters,
    ));
    _baseBuilder.extension(LLMConfigKeys.builtInTools, tools);
    return this;
  }

  /// Helper method to get or create built-in tools list
  List<OpenAIBuiltInTool> _getBuiltInTools() {
    final existingTools = _baseBuilder.currentConfig
        .getExtension<List<OpenAIBuiltInTool>>(LLMConfigKeys.builtInTools);
    return existingTools != null
        ? List.from(existingTools)
        : <OpenAIBuiltInTool>[];
  }

  // ========== OpenAI Web Search Configuration ==========

  /// Configures web search for OpenAI models
  ///
  /// OpenAI supports web search through specific models like `gpt-4o-search-preview`
  /// and provides context size control for search results.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .openai((openai) => openai
  ///         .webSearch(contextSize: WebSearchContextSize.high))
  ///     .apiKey(apiKey)
  ///     .model('gpt-4o-search-preview')
  ///     .build();
  /// ```
  OpenAIBuilder webSearch({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
  }) {
    _baseBuilder.extension(
        LLMConfigKeys.webSearchConfig,
        WebSearchConfig.openai(
          contextSize: contextSize,
        ));
    return this;
  }

  // ========== Convenience methods for common configurations ==========

  /// Configure for creative writing with reduced repetition
  ///
  /// Sets moderate frequency and presence penalties to encourage
  /// diverse and creative output while maintaining coherence.
  OpenAIBuilder forCreativeWriting() {
    return frequencyPenalty(0.5).presencePenalty(0.6).parallelToolCalls(false);
  }

  /// Configure for factual and consistent responses
  ///
  /// Sets low penalties and enables deterministic behavior for
  /// consistent, factual responses.
  OpenAIBuilder forFactualResponses({int? seed}) {
    final builder =
        frequencyPenalty(0.0).presencePenalty(0.0).parallelToolCalls(true);

    if (seed != null) {
      builder.seed(seed);
    }

    return builder;
  }

  /// Configure for code generation with deterministic output
  ///
  /// Optimized settings for code generation tasks with consistent
  /// formatting and reduced randomness.
  OpenAIBuilder forCodeGeneration({int? seed}) {
    final builder =
        frequencyPenalty(0.1).presencePenalty(0.1).parallelToolCalls(true);

    if (seed != null) {
      builder.seed(seed);
    }

    return builder;
  }

  /// Configure for conversational AI with balanced creativity
  ///
  /// Balanced settings for natural conversation with some creativity
  /// while avoiding excessive repetition.
  OpenAIBuilder forConversation() {
    return frequencyPenalty(0.3).presencePenalty(0.4).parallelToolCalls(true);
  }

  /// Configure for analysis tasks with log probabilities
  ///
  /// Enables log probabilities for confidence analysis and
  /// sets conservative penalties for analytical tasks.
  OpenAIBuilder forAnalysis({int topLogprobsCount = 5}) {
    return frequencyPenalty(0.1)
        .presencePenalty(0.1)
        .logprobs(true)
        .topLogprobs(topLogprobsCount)
        .parallelToolCalls(true);
  }

  // ========== Build methods ==========

  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with AudioCapability
  Future<AudioCapability> buildAudio() async {
    return _baseBuilder.buildAudio();
  }

  /// Builds a provider with ImageGenerationCapability
  Future<ImageGenerationCapability> buildImageGeneration() async {
    return _baseBuilder.buildImageGeneration();
  }

  /// Builds a provider with EmbeddingCapability
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  /// Builds a provider with FileManagementCapability
  Future<FileManagementCapability> buildFileManagement() async {
    return _baseBuilder.buildFileManagement();
  }

  /// Builds a provider with ModerationCapability
  Future<ModerationCapability> buildModeration() async {
    return _baseBuilder.buildModeration();
  }

  /// Builds a provider with AssistantCapability
  Future<AssistantCapability> buildAssistant() async {
    return _baseBuilder.buildAssistant();
  }

  /// Builds a provider with ModelListingCapability
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }

  /// Builds an OpenAI provider with Responses API enabled
  ///
  /// This is a convenience method that automatically:
  /// - Enables the Responses API (`useResponsesAPI(true)`)
  /// - Returns a properly typed OpenAIProvider with Responses API access
  /// - Ensures the `openaiResponses` capability is available
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
  /// // Direct access to Responses API
  /// final responsesAPI = provider.responses!;
  /// final response = await responsesAPI.chat(messages);
  /// ```
  ///
  /// **Note**: This method automatically enables Responses API even if not
  /// explicitly called with `useResponsesAPI()`. The returned provider will
  /// always support `LLMCapability.openaiResponses`.
  Future<openai_impl.OpenAIProvider> buildOpenAIResponses() async {
    // Automatically enable Responses API if not already enabled
    final isResponsesAPIEnabled = _baseBuilder.currentConfig
            .getExtension<bool>(LLMConfigKeys.useResponsesAPI) ??
        false;
    if (!isResponsesAPIEnabled) {
      useResponsesAPI(true);
    }

    final provider = await build();

    // Ensure we have an OpenAI provider. If the current builder is configured
    // for a non‑OpenAI backend (e.g. Anthropic), surface this as a capability
    // error instead of an internal StateError so callers can handle it
    // consistently with other build* helpers.
    if (provider is! openai_impl.OpenAIProvider) {
      throw UnsupportedCapabilityError(
        'OpenAI Responses API is only available for OpenAI-compatible providers. '
        'Received provider type: ${provider.runtimeType}.',
      );
    }

    // Verify that Responses API is properly initialized
    if (provider.responses == null) {
      throw StateError('OpenAI Responses API not properly initialized. '
          'This should not happen when using buildOpenAIResponses().');
    }

    return provider;
  }
}
