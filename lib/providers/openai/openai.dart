// The OpenAI provider facade intentionally exposes ChatMessage-based
// chat APIs as part of the public surface for backwards compatibility.
// New code should prefer ModelMessage + ChatContentPart via helpers.
// ignore_for_file: deprecated_member_use

/// Modular OpenAI Provider
///
/// This library provides a modular implementation of the OpenAI provider
///
/// **Key Benefits:**
/// - Single Responsibility: Each module handles one capability
/// - Easier Testing: Modules can be tested independently
/// - Better Maintainability: Changes isolated to specific modules
/// - Cleaner Code: Smaller, focused classes
/// - Reusability: Modules can be reused across providers
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/openai/openai.dart';
///
/// final provider = ModularOpenAIProvider(ModularOpenAIConfig(
///   apiKey: 'your-api-key',
///   model: 'gpt-4',
/// ));
///
/// // Use any capability - same external API
/// final response = await provider.chat(messages);
/// final embeddings = await provider.embed(['text']);
/// final audio = await provider.speech('Hello world');
/// ```
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai/llm_dart_openai.dart' as openai_impl;

import 'builtin_tools.dart';
import '../../utils/provider_registry.dart'
    show
        LanguageModelProviderFactory,
        EmbeddingModelProviderFactory,
        ImageModelProviderFactory,
        SpeechModelProviderFactory;

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';
export 'audio.dart';
export 'images.dart';
export 'files.dart';
export 'models.dart';
export 'moderation.dart';
export 'assistants.dart';
export 'completion.dart';
export 'responses.dart';
export 'builtin_tools.dart';

/// Local defaults for OpenAI and related providers (OpenRouter, Groq, DeepSeek, Copilot, Together).
const _openaiBaseUrl = 'https://api.openai.com/v1/';
const _openaiDefaultModel = 'gpt-4o';
const _openRouterBaseUrl = 'https://openrouter.ai/api/v1/';
const _openRouterDefaultModel = 'openai/gpt-4';
const _groqBaseUrl = 'https://api.groq.com/openai/v1/';
const _groqDefaultModel = 'llama-3.3-70b-versatile';
const _deepseekBaseUrl = 'https://api.deepseek.com/v1/';
const _deepseekDefaultModel = 'deepseek-chat';
const _githubCopilotBaseUrl = 'https://api.githubcopilot.com/chat/completions';
const _githubCopilotDefaultModel = 'gpt-4';
const _togetherAIBaseUrl = 'https://api.together.xyz/v1/';
const _togetherAIDefaultModel = 'meta-llama/Llama-3-70b-chat-hf';

/// OpenAI provider settings (Vercel AI-style).
///
/// This mirrors the core fields from `OpenAIProviderSettings` in the
/// Vercel AI SDK while adopting Dart conventions:
/// - [apiKey] is required instead of being read from environment variables.
/// - [baseUrl], [organization], [project] and [headers] are optional
///   overrides for HTTP configuration.
class OpenAIProviderSettings {
  /// API key used for authenticating requests.
  final String apiKey;

  /// Base URL for the OpenAI API.
  ///
  /// Defaults to `https://api.openai.com/v1/` when not provided.
  final String? baseUrl;

  /// OpenAI organization header (`OpenAI-Organization`).
  final String? organization;

  /// OpenAI project header (`OpenAI-Project`).
  final String? project;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `openai`, `my-openai-proxy`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const OpenAIProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.organization,
    this.project,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// Facade for creating OpenAI models in a Vercel AI-compatible style.
///
/// This class provides methods that closely mirror the `OpenAIProvider`
/// interface from the Vercel AI SDK:
///
/// - [languageModel] / [responses] → OpenAI Responses API models
/// - [chat] → Chat Completions-style models
/// - [embedding] / [textEmbedding] / [textEmbeddingModel] → Embedding models
/// - [image] / [imageModel] → Image generation models
/// - [transcription] → Speech-to-text models
/// - [speech] → Text-to-speech models
///
/// The methods return strongly-typed capability interfaces from
/// `llm_dart_core`, with chat-style models wrapped as [LanguageModel]
/// to align with the AI SDK's language model abstraction.
class OpenAI
    implements
        LanguageModelProviderFactory,
        EmbeddingModelProviderFactory,
        ImageModelProviderFactory,
        SpeechModelProviderFactory {
  final OpenAIProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  OpenAI(OpenAIProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _openaiBaseUrl,
        ),
        _providerName = settings.name ?? 'openai';

  /// Create a language model using the OpenAI Responses API.
  ///
  /// This is the primary entry point and is equivalent to [responses].
  @override
  LanguageModel languageModel(String modelId) => responses(modelId);

  /// Create a chat model using the Chat Completions API.
  ///
  /// This maps to the non-Responses chat endpoint and is suitable for
  /// most general-purpose chat use cases.
  LanguageModel chat(String modelId) {
    final config = _createOpenAIConfig(
      modelId: modelId,
      useResponsesAPI: false,
    );
    final client = openai_impl.OpenAIClient(config);
    final chat = openai_impl.OpenAIChat(client, config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: config.originalConfig!,
      chat: chat,
    );
  }

  /// Create a language model backed by the OpenAI Responses API.
  ///
  /// This enables advanced features such as:
  /// - Built-in tools (web search, file search, computer use)
  /// - Background responses and response lifecycle management
  /// - Reasoning-aware streaming with thinking deltas
  OpenAIResponsesModel responses(String modelId) {
    final config = _createOpenAIConfig(
      modelId: modelId,
      useResponsesAPI: true,
    );
    final client = openai_impl.OpenAIClient(config);
    final responses = openai_impl.OpenAIResponses(client, config);

    return OpenAIResponsesModel(
      providerId: '$_providerName.responses',
      modelId: modelId,
      config: config.originalConfig!,
      responses: responses,
    );
  }

  /// Create an embedding model.
  ///
  /// Returns an [EmbeddingCapability] that can be used with
  /// `embed(input, cancelToken: ...)`.
  EmbeddingCapability embedding(String modelId) {
    final config = _createOpenAIConfig(modelId: modelId);
    final client = openai_impl.OpenAIClient(config);
    return openai_impl.OpenAIEmbeddings(client, config);
  }

  /// Alias for [embedding] to mirror the Vercel AI SDK.
  EmbeddingCapability textEmbedding(String modelId) => embedding(modelId);

  /// Alias for [embedding] to mirror the Vercel AI SDK.
  @override
  EmbeddingCapability textEmbeddingModel(String modelId) => embedding(modelId);

  /// Create an image generation model.
  ///
  /// Returns an [ImageGenerationCapability] that can generate images
  /// using OpenAI's image endpoints (e.g. DALL·E).
  ImageGenerationCapability image(String modelId) => imageModel(modelId);

  /// Alias for [image] to mirror the Vercel AI SDK.
  @override
  ImageGenerationCapability imageModel(String modelId) {
    final config = _createOpenAIConfig(modelId: modelId);
    final client = openai_impl.OpenAIClient(config);
    return openai_impl.OpenAIImages(client, config);
  }

  /// Create a transcription model (speech-to-text).
  ///
  /// Returns an [AudioCapability] configured for speech recognition.
  @override
  AudioCapability transcription(String modelId) {
    final config = _createOpenAIConfig(modelId: modelId);
    final client = openai_impl.OpenAIClient(config);
    return openai_impl.OpenAIAudio(client, config);
  }

  /// Create a speech model (text-to-speech).
  ///
  /// Returns an [AudioCapability] configured for text-to-speech.
  @override
  AudioCapability speech(String modelId) => transcription(modelId);

  /// OpenAI built-in tools (web search, file search, computer use).
  ///
  /// This mirrors the `openai.tools` namespace from the Vercel AI SDK.
  OpenAITools get tools => const OpenAITools();

  /// Internal helper to create a base [LLMConfig] for a given model.
  LLMConfig _createLLMConfig(String modelId) {
    final headers = <String, String>{};

    if (_settings.organization != null && _settings.organization!.isNotEmpty) {
      headers['OpenAI-Organization'] = _settings.organization!;
    }

    if (_settings.project != null && _settings.project!.isNotEmpty) {
      headers['OpenAI-Project'] = _settings.project!;
    }

    if (_settings.headers != null && _settings.headers!.isNotEmpty) {
      headers.addAll(_settings.headers!);
    }

    final extensions = <String, dynamic>{};
    if (headers.isNotEmpty) {
      extensions[LLMConfigKeys.customHeaders] = headers;
    }

    return LLMConfig(
      apiKey: _settings.apiKey,
      baseUrl: _baseUrl,
      model: modelId,
      timeout: _settings.timeout,
      extensions: extensions,
    );
  }

  /// Internal helper to create an [openai_impl.OpenAIConfig] for a given model.
  openai_impl.OpenAIConfig _createOpenAIConfig({
    required String modelId,
    bool useResponsesAPI = false,
  }) {
    final baseConfig = _createLLMConfig(modelId);

    return openai_impl.OpenAIConfig(
      apiKey: _settings.apiKey,
      baseUrl: _baseUrl,
      model: modelId,
      timeout: _settings.timeout,
      useResponsesAPI: useResponsesAPI,
      originalConfig: baseConfig,
    );
  }

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return _openaiBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// LanguageModel wrapper for the OpenAI Responses API.
///
/// This type implements both [LanguageModel] and the full
/// [openai_impl.OpenAIResponsesCapability] interface so that it can be used
/// with high-level helpers (`generateTextWithModel`) and also access the
/// underlying Responses API features (background responses, lifecycle
/// management, response chaining, etc.).
class OpenAIResponsesModel
    implements LanguageModel, openai_impl.OpenAIResponsesCapability {
  final DefaultLanguageModel _model;
  final openai_impl.OpenAIResponses _responses;

  OpenAIResponsesModel({
    required String providerId,
    required String modelId,
    required LLMConfig config,
    required openai_impl.OpenAIResponses responses,
  })  : _responses = responses,
        _model = DefaultLanguageModel(
          providerId: providerId,
          modelId: modelId,
          config: config,
          chat: responses,
        );

  @override
  String get providerId => _model.providerId;

  @override
  String get modelId => _model.modelId;

  @override
  LLMConfig get config => _model.config;

  @override
  Future<GenerateTextResult> generateText(
    List<ModelMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return _model.generateText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<ChatStreamEvent> streamText(
    List<ModelMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return _model.streamText(messages, cancelToken: cancelToken);
  }

  @override
  Stream<StreamTextPart> streamTextParts(
    List<ModelMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return _model.streamTextParts(messages, cancelToken: cancelToken);
  }

  @override
  Future<GenerateObjectResult<T>> generateObject<T>(
    OutputSpec<T> output,
    List<ModelMessage> messages, {
    CancellationToken? cancelToken,
  }) {
    return _model.generateObject(
      output,
      messages,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<GenerateTextResult> generateTextWithOptions(
    List<ModelMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    // Delegate to the underlying DefaultLanguageModel implementation.
    return _model.generateTextWithOptions(
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<ChatStreamEvent> streamTextWithOptions(
    List<ModelMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _model.streamTextWithOptions(
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<StreamTextPart> streamTextPartsWithOptions(
    List<ModelMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _model.streamTextPartsWithOptions(
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<GenerateObjectResult<T>> generateObjectWithOptions<T>(
    OutputSpec<T> output,
    List<ModelMessage> messages, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _model.generateObjectWithOptions(
      output,
      messages,
      options: options,
      cancelToken: cancelToken,
    );
  }

  // ===== OpenAIResponsesCapability delegation =====

  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) {
    return _responses.chatWithTools(messages, tools);
  }

  @override
  Future<ChatResponse> chatWithToolsBackground(
    List<ChatMessage> messages,
    List<Tool>? tools,
  ) {
    return _responses.chatWithToolsBackground(messages, tools);
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
  }) {
    return _responses.chatStream(messages, tools: tools);
  }

  @override
  Future<ChatResponse> getResponse(
    String responseId, {
    List<String>? include,
    int? startingAfter,
    bool stream = false,
  }) {
    return _responses.getResponse(
      responseId,
      include: include,
      startingAfter: startingAfter,
      stream: stream,
    );
  }

  @override
  Future<bool> deleteResponse(String responseId) {
    return _responses.deleteResponse(responseId);
  }

  @override
  Future<ChatResponse> cancelResponse(String responseId) {
    return _responses.cancelResponse(responseId);
  }

  @override
  Future<ResponseInputItemsList> listInputItems(
    String responseId, {
    String? after,
    String? before,
    List<String>? include,
    int limit = 20,
    String order = 'desc',
  }) {
    return _responses.listInputItems(
      responseId,
      after: after,
      before: before,
      include: include,
      limit: limit,
      order: order,
    );
  }

  @override
  Future<ChatResponse> continueConversation(
    String previousResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) {
    return _responses.continueConversation(
      previousResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
  }

  @override
  Future<ChatResponse> forkConversation(
    String fromResponseId,
    List<ChatMessage> newMessages, {
    List<Tool>? tools,
    bool background = false,
  }) {
    return _responses.forkConversation(
      fromResponseId,
      newMessages,
      tools: tools,
      background: background,
    );
  }
}

/// Lightweight facade around [OpenAIBuiltInTools] to mirror the
/// `openai.tools` namespace from the Vercel AI SDK.
class OpenAITools {
  const OpenAITools();

  /// Create an OpenAI web search tool.
  ///
  /// Mirrors `openai.tools.webSearch` from the Vercel AI SDK:
  /// - [allowedDomains] → filters.allowed_domains
  /// - [contextSize] → search_context_size
  /// - [location] → user_location
  OpenAIWebSearchTool webSearch({
    List<String>? allowedDomains,
    WebSearchContextSize? contextSize,
    WebSearchLocation? location,
  }) =>
      OpenAIBuiltInTools.webSearch(
        allowedDomains: allowedDomains,
        contextSize: contextSize,
        location: location,
      );

  OpenAIFileSearchTool fileSearch({
    List<String>? vectorStoreIds,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIBuiltInTools.fileSearch(
        vectorStoreIds: vectorStoreIds,
        parameters: parameters,
      );

  OpenAIComputerUseTool computerUse({
    required int displayWidth,
    required int displayHeight,
    required String environment,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIBuiltInTools.computerUse(
        displayWidth: displayWidth,
        displayHeight: displayHeight,
        environment: environment,
        parameters: parameters,
      );
}

/// Create an OpenAI provider with default settings
openai_impl.OpenAIProvider createOpenAIProvider({
  required String apiKey,
  String model = _openaiDefaultModel,
  String baseUrl = _openaiBaseUrl,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}

/// Create an OpenAI model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final openai = createOpenAI(
///   apiKey: 'sk-...',
///   baseUrl: 'https://api.openai.com/v1/',
/// );
///
/// final model = openai.chat('gpt-4o');
/// final result = await generateTextWithModel(
///   model: model,
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
OpenAI createOpenAI({
  required String apiKey,
  String? baseUrl,
  String? organization,
  String? project,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return OpenAI(
    OpenAIProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      organization: organization,
      project: project,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createOpenAI] to mirror the default `openai` export
/// from the Vercel AI SDK.
OpenAI openai({
  required String apiKey,
  String? baseUrl,
  String? organization,
  String? project,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createOpenAI(
    apiKey: apiKey,
    baseUrl: baseUrl,
    organization: organization,
    project: project,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

/// Create an OpenAI provider for OpenRouter
///
/// This legacy helper treats OpenRouter as an OpenAI-compatible endpoint.
/// New code should prefer the dedicated OpenAI-compatible provider via
/// `ai().openRouter()` / `OpenAICompatibleProviderFactory` or use the
/// `OpenAICompatibleConfigs.openrouter(...)` helper from
/// `package:llm_dart_openai_compatible`.
@Deprecated(
  'Use the OpenAI-compatible provider via ai().openRouter() '
  'or OpenAICompatibleConfigs.openrouter(...) instead of '
  'createOpenRouterProvider on the OpenAI facade.',
)
openai_impl.OpenAIProvider createOpenRouterProvider({
  required String apiKey,
  String model = _openRouterDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: _openRouterBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}

/// Create an OpenAI provider for Groq.
///
/// This legacy helper treats Groq as an OpenAI-compatible endpoint.
/// New code should prefer the dedicated Groq provider from
/// `package:llm_dart/providers/groq/groq.dart` or use
/// `ai().groq()` / `GroqProviderFactory` instead.
@Deprecated(
  'Use GroqProvider from package:llm_dart/providers/groq/groq.dart '
  'or ai().groq() instead of createGroqProvider on the OpenAI facade.',
)
openai_impl.OpenAIProvider createGroqProvider({
  required String apiKey,
  String model = _groqDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: _groqBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}

/// Create an OpenAI provider for DeepSeek.
///
/// This legacy helper treats DeepSeek as an OpenAI-compatible endpoint.
/// New code should prefer the dedicated DeepSeek provider from
/// `package:llm_dart/providers/deepseek/deepseek.dart` or use
/// `ai().deepseek()` / `DeepSeekProviderFactory` instead.
@Deprecated(
  'Use DeepSeekProvider from package:llm_dart/providers/deepseek/deepseek.dart '
  'or ai().deepseek() instead of createDeepSeekProvider on the OpenAI facade.',
)
openai_impl.OpenAIProvider createDeepSeekProvider({
  required String apiKey,
  String model = _deepseekDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: _deepseekBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}

/// Create an OpenAI provider for Azure OpenAI
openai_impl.OpenAIProvider createAzureOpenAIProvider({
  required String apiKey,
  required String endpoint,
  required String deploymentName,
  String apiVersion = '2024-02-15-preview',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: deploymentName,
    baseUrl: '$endpoint/openai/deployments/$deploymentName/',
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}

/// Create an OpenAI provider for GitHub Copilot
///
/// This helper treats GitHub Copilot as an OpenAI-compatible endpoint.
/// New code should prefer a dedicated OpenAI-compatible configuration
/// instead of reusing the OpenAI facade.
@Deprecated(
  'Use an OpenAI-compatible configuration for GitHub Copilot instead of '
  'createCopilotProvider on the OpenAI facade. '
  'This helper will be removed in a future release.',
)
openai_impl.OpenAIProvider createCopilotProvider({
  required String apiKey,
  String model = _githubCopilotDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: _githubCopilotBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}

/// Create an OpenAI provider for Together AI
///
/// This helper treats Together AI as an OpenAI-compatible endpoint.
/// New code should prefer a dedicated OpenAI-compatible configuration
/// instead of reusing the OpenAI facade.
@Deprecated(
  'Use an OpenAI-compatible configuration for Together AI instead of '
  'createTogetherProvider on the OpenAI facade. '
  'This helper will be removed in a future release.',
)
openai_impl.OpenAIProvider createTogetherProvider({
  required String apiKey,
  String model = _togetherAIDefaultModel,
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = openai_impl.OpenAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: _togetherAIBaseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return openai_impl.OpenAIProvider(config);
}
