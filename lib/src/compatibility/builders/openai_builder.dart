import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../../../core/web_search.dart';
import '../../../models/chat_models.dart';
import '../../../models/tool_models.dart';
import '../../../providers/openai/builtin_tools.dart';
import '../../../providers/openai/provider.dart';
import '../config/legacy_config_keys.dart';
import '../providers/openai/assistant_capability.dart';
import '../web_search_presets.dart';
import 'legacy_builder_provider_options.dart';

/// Compatibility-only OpenAI builder DSL for the legacy root provider surface.
///
/// This builder remains public because the repository still keeps the old root
/// `OpenAIProvider` compatibility surface alive, especially for residual APIs
/// such as raw Responses lifecycle helpers.
///
/// New code should usually prefer the stable `openai(...).chatModel(...)` path
/// plus typed provider-owned options from `package:llm_dart/openai.dart`.
class OpenAIBuilder {
  final LLMBuilder _baseBuilder;
  final LegacyBuilderProviderOptionWriter _providerOptions;

  OpenAIBuilder(LLMBuilder baseBuilder)
      : _baseBuilder = baseBuilder,
        _providerOptions =
            LegacyBuilderProviderOptionWriter.openAI(baseBuilder);

  /// Sets frequency penalty for reducing repetition (-2.0 to 2.0).
  OpenAIBuilder frequencyPenalty(double penalty) {
    _providerOptions.set(LegacyExtensionKeys.frequencyPenalty, penalty);
    return this;
  }

  /// Sets reasoning effort for models that support it.
  OpenAIBuilder reasoningEffort(ReasoningEffort effort) {
    _providerOptions.set(LegacyExtensionKeys.reasoningEffort, effort.value);
    return this;
  }

  /// Sets structured output schema for JSON responses.
  OpenAIBuilder jsonSchema(StructuredOutputFormat schema) {
    _providerOptions.set(LegacyExtensionKeys.jsonSchema, schema);
    return this;
  }

  /// Sets voice for text-to-speech requests.
  OpenAIBuilder voice(String voiceName) {
    _providerOptions.set(LegacyExtensionKeys.voice, voiceName);
    return this;
  }

  /// Sets embedding encoding format.
  OpenAIBuilder embeddingEncodingFormat(String format) {
    _providerOptions.set(
      LegacyExtensionKeys.embeddingEncodingFormat,
      format,
    );
    return this;
  }

  /// Sets embedding dimensions.
  OpenAIBuilder embeddingDimensions(int dimensions) {
    _providerOptions.set(
      LegacyExtensionKeys.embeddingDimensions,
      dimensions,
    );
    return this;
  }

  /// Sets presence penalty for encouraging topic diversity (-2.0 to 2.0).
  OpenAIBuilder presencePenalty(double penalty) {
    _providerOptions.set(LegacyExtensionKeys.presencePenalty, penalty);
    return this;
  }

  /// Sets logit bias for specific tokens.
  OpenAIBuilder logitBias(Map<String, double> bias) {
    _providerOptions.set(LegacyExtensionKeys.logitBias, bias);
    return this;
  }

  /// Sets seed for deterministic outputs.
  OpenAIBuilder seed(int seedValue) {
    _providerOptions.set(LegacyExtensionKeys.seed, seedValue);
    return this;
  }

  /// Enables or disables parallel tool calls.
  OpenAIBuilder parallelToolCalls(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.parallelToolCalls, enabled);
    return this;
  }

  /// Enables or disables log probabilities.
  OpenAIBuilder logprobs(bool enabled) {
    _providerOptions.set(LegacyExtensionKeys.logprobs, enabled);
    return this;
  }

  /// Sets the number of most likely tokens to return log probabilities for.
  OpenAIBuilder topLogprobs(int count) {
    _providerOptions.set(LegacyExtensionKeys.topLogprobs, count);
    return this;
  }

  /// Sets verbosity level for GPT-5 family models.
  OpenAIBuilder verbosity(Verbosity level) {
    _providerOptions.set(LegacyExtensionKeys.verbosity, level.value);
    return this;
  }

  /// Enables the Responses API instead of Chat Completions API.
  OpenAIBuilder useResponsesAPI([bool use = true]) {
    _providerOptions.set(LegacyExtensionKeys.useResponsesApi, use);
    return this;
  }

  /// Sets previous response ID for chaining responses.
  OpenAIBuilder previousResponseId(String responseId) {
    _providerOptions.set(
      LegacyExtensionKeys.previousResponseId,
      responseId,
    );
    return this;
  }

  /// Adds web search built-in tool.
  OpenAIBuilder webSearchTool() {
    final tools = _getBuiltInTools();
    tools.add(OpenAIBuiltInTools.webSearch());
    _providerOptions.set(LegacyExtensionKeys.builtInTools, tools);
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
    _providerOptions.set(LegacyExtensionKeys.builtInTools, tools);
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
    _providerOptions.set(LegacyExtensionKeys.builtInTools, tools);
    return this;
  }

  List<OpenAIBuiltInTool> _getBuiltInTools() {
    final existingTools = _providerOptions.get<List<OpenAIBuiltInTool>>(
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
    _providerOptions.set(
      LegacyExtensionKeys.webSearchConfig,
      CompatWebSearchPresets.openai(
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

  /// Builds a provider with OpenAI assistant capability.
  Future<AssistantCapability> buildAssistant() async {
    return _baseBuilder.buildAssistant();
  }

  /// Builds a provider with ModelListingCapability.
  Future<ModelListingCapability> buildModelListing() async {
    return _baseBuilder.buildModelListing();
  }

  /// Builds an OpenAI provider with Responses API enabled.
  Future<OpenAIProvider> buildOpenAIResponses() async {
    final isResponsesApiEnabled =
        _providerOptions.get<bool>(LegacyExtensionKeys.useResponsesApi) ??
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
}
