import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/provider.dart';
import '../../config/legacy_config_keys.dart';
import '../../config/legacy_provider_options.dart';

/// Compatibility-only OpenAI builder DSL for the legacy root provider surface.
///
/// This builder remains public because the repository still keeps the old root
/// `OpenAIProvider` compatibility surface alive, especially for residual APIs
/// such as raw Responses lifecycle helpers.
///
/// New code should usually prefer the stable `AI.openai(...).chatModel(...)`
/// path plus typed provider-owned options from `package:llm_dart/openai.dart`.
class OpenAIBuilder {
  final LLMBuilder _baseBuilder;

  OpenAIBuilder(this._baseBuilder);

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0).
  OpenAIBuilder frequencyPenalty(double penalty) {
    _setOpenAIProviderOption(LegacyExtensionKeys.frequencyPenalty, penalty);
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0).
  OpenAIBuilder presencePenalty(double penalty) {
    _setOpenAIProviderOption(LegacyExtensionKeys.presencePenalty, penalty);
    return this;
  }

  /// Sets logit bias for specific tokens.
  OpenAIBuilder logitBias(Map<String, double> bias) {
    _setOpenAIProviderOption(LegacyExtensionKeys.logitBias, bias);
    return this;
  }

  /// Sets seed for deterministic outputs.
  OpenAIBuilder seed(int seedValue) {
    _setOpenAIProviderOption(LegacyExtensionKeys.seed, seedValue);
    return this;
  }

  /// Enables or disables parallel tool calls.
  OpenAIBuilder parallelToolCalls(bool enabled) {
    _setOpenAIProviderOption(LegacyExtensionKeys.parallelToolCalls, enabled);
    return this;
  }

  /// Enables or disables log probabilities.
  OpenAIBuilder logprobs(bool enabled) {
    _setOpenAIProviderOption(LegacyExtensionKeys.logprobs, enabled);
    return this;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  OpenAIBuilder topLogprobs(int count) {
    _setOpenAIProviderOption(LegacyExtensionKeys.topLogprobs, count);
    return this;
  }

  /// Sets verbosity level for GPT-5 family models.
  OpenAIBuilder verbosity(Verbosity level) {
    _setOpenAIProviderOption(LegacyExtensionKeys.verbosity, level.value);
    return this;
  }

  /// Enables the Responses API instead of Chat Completions API.
  OpenAIBuilder useResponsesAPI([bool use = true]) {
    _setOpenAIProviderOption(LegacyExtensionKeys.useResponsesApi, use);
    return this;
  }

  /// Sets previous response ID for chaining responses.
  OpenAIBuilder previousResponseId(String responseId) {
    _setOpenAIProviderOption(
      LegacyExtensionKeys.previousResponseId,
      responseId,
    );
    return this;
  }

  /// Adds web search built-in tool.
  OpenAIBuilder webSearchTool() {
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.webSearch());
    _setOpenAIProviderOption(LegacyExtensionKeys.builtInTools, tools);
    return this;
  }

  /// Adds file search built-in tool.
  OpenAIBuilder fileSearchTool({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) {
    final tools = _getBuiltInTools();
    tools.add(
      OpenAIBuiltInTools.fileSearch(
        vectorStoreIds: vectorStoreIds,
        parameters: parameters,
      ),
    );
    _setOpenAIProviderOption(LegacyExtensionKeys.builtInTools, tools);
    return this;
  }

  /// Adds computer use built-in tool.
  OpenAIBuilder computerUseTool({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) {
    final tools = _getBuiltInTools();
    tools.add(
      OpenAIBuiltInTools.computerUse(
        displayWidth: displayWidth,
        displayHeight: displayHeight,
        environment: environment,
        parameters: parameters,
      ),
    );
    _setOpenAIProviderOption(LegacyExtensionKeys.builtInTools, tools);
    return this;
  }

  List<OpenAIBuiltInTool> _getBuiltInTools() {
    final existingTools = getLegacyProviderOption<List<OpenAIBuiltInTool>>(
      _baseBuilder.currentConfig,
      LegacyProviderOptionNamespaces.openai,
      LegacyExtensionKeys.builtInTools,
    );
    return existingTools != null
        ? List.from(existingTools)
        : <OpenAIBuiltInTool>[];
  }

  /// Configures web search for OpenAI models.
  OpenAIBuilder webSearch({
    WebSearchContextSize contextSize = WebSearchContextSize.medium,
  }) {
    _setOpenAIProviderOption(
      LegacyExtensionKeys.webSearchConfig,
      WebSearchConfig.openai(
        contextSize: contextSize,
      ),
    );
    return this;
  }

  /// Configure for creative writing with reduced repetition.
  OpenAIBuilder forCreativeWriting() {
    return frequencyPenalty(0.5).presencePenalty(0.6).parallelToolCalls(false);
  }

  /// Configure for factual and consistent responses.
  OpenAIBuilder forFactualResponses({int? seed}) {
    final builder =
        frequencyPenalty(0.0).presencePenalty(0.0).parallelToolCalls(true);

    if (seed != null) {
      builder.seed(seed);
    }

    return builder;
  }

  /// Configure for code generation with deterministic output.
  OpenAIBuilder forCodeGeneration({int? seed}) {
    final builder =
        frequencyPenalty(0.1).presencePenalty(0.1).parallelToolCalls(true);

    if (seed != null) {
      builder.seed(seed);
    }

    return builder;
  }

  /// Configure for conversational AI with balanced creativity.
  OpenAIBuilder forConversation() {
    return frequencyPenalty(0.3).presencePenalty(0.4).parallelToolCalls(true);
  }

  /// Configure for analysis tasks with log probabilities.
  OpenAIBuilder forAnalysis({int topLogprobsCount = 5}) {
    return frequencyPenalty(0.1)
        .presencePenalty(0.1)
        .logprobs(true)
        .topLogprobs(topLogprobsCount)
        .parallelToolCalls(true);
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with AudioCapability.
  Future<AudioCapability> buildAudio() async {
    return _baseBuilder.buildAudio();
  }

  /// Builds a provider with ImageGenerationCapability.
  Future<ImageGenerationCapability> buildImageGeneration() async {
    return _baseBuilder.buildImageGeneration();
  }

  /// Builds a provider with EmbeddingCapability.
  Future<EmbeddingCapability> buildEmbedding() async {
    return _baseBuilder.buildEmbedding();
  }

  /// Builds a provider with FileManagementCapability.
  Future<FileManagementCapability> buildFileManagement() async {
    return _baseBuilder.buildFileManagement();
  }

  /// Builds a provider with ModerationCapability.
  Future<ModerationCapability> buildModeration() async {
    return _baseBuilder.buildModeration();
  }

  /// Builds a provider with AssistantCapability.
  Future<AssistantCapability> buildAssistant() async {
    return _baseBuilder.buildAssistant();
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }

  /// Builds an OpenAI provider with Responses API enabled.
  Future<OpenAIProvider> buildOpenAIResponses() async {
    final isResponsesApiEnabled = getLegacyProviderOption<bool>(
          _baseBuilder.currentConfig,
          LegacyProviderOptionNamespaces.openai,
          LegacyExtensionKeys.useResponsesApi,
        ) ??
        false;
    if (!isResponsesApiEnabled) {
      useResponsesAPI(true);
    }

    final provider = await build();

    if (provider is! OpenAIProvider) {
      throw StateError(
        'Expected OpenAIProvider but got ${provider.runtimeType}. '
        'This should not happen when using buildOpenAIResponses().',
      );
    }

    if (provider.responses == null) {
      throw StateError(
        'OpenAI Responses API not properly initialized. '
        'This should not happen when using buildOpenAIResponses().',
      );
    }

    return provider;
  }

  void _setOpenAIProviderOption(String key, dynamic value) {
    final providerOptions = setLegacyProviderOption(
      _baseBuilder.currentConfig,
      LegacyProviderOptionNamespaces.openai,
      key,
      value,
    );

    _baseBuilder.extension(legacyProviderOptionsBagKey, providerOptions);
  }
}
