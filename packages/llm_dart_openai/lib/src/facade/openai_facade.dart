import 'package:llm_dart_core/llm_dart_core.dart';

import '../audio/openai_audio.dart';
import '../chat/openai_chat.dart';
import '../client/openai_client.dart';
import '../config/openai_config.dart';
import '../embeddings/openai_embeddings.dart';
import '../images/openai_images.dart';
import '../responses/openai_responses.dart';
import '../responses/openai_responses_capability.dart';
import '../tools/openai_builtin_tools.dart';

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
  /// Defaults to [openaiDefaultBaseUrl] when not provided.
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
          settings.baseUrl ?? openaiDefaultBaseUrl,
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
    final client = OpenAIClient(config);
    final chat = OpenAIChat(client, config);

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
  ///
  /// You can optionally attach OpenAI built-in tools (mirroring the
  /// `openai.tools.*` helpers in the Vercel AI SDK) via [builtInTools]:
  ///
  /// ```dart
  /// final openai = createOpenAI(apiKey: apiKey);
  ///
  /// final model = openai.responses(
  ///   'gpt-4o',
  ///   builtInTools: [
  ///     openai.tools.webSearch(
  ///       contextSize: WebSearchContextSize.medium,
  ///     ),
  ///   ],
  /// );
  /// ```
  OpenAIResponsesModel responses(
    String modelId, {
    List<OpenAIBuiltInTool>? builtInTools,
  }) {
    final config = _createOpenAIConfig(
      modelId: modelId,
      useResponsesAPI: true,
      builtInTools: builtInTools,
    );
    final client = OpenAIClient(config);
    final responses = OpenAIResponses(client, config);

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
    final client = OpenAIClient(config);
    return OpenAIEmbeddings(client, config);
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
    final client = OpenAIClient(config);
    return OpenAIImages(client, config);
  }

  /// Create a transcription model (speech-to-text).
  ///
  /// Returns an [AudioCapability] configured for speech recognition.
  @override
  AudioCapability transcription(String modelId) {
    final config = _createOpenAIConfig(modelId: modelId);
    final client = OpenAIClient(config);
    return OpenAIAudio(client, config);
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

  /// Provider-defined tools for OpenAI Responses API.
  ///
  /// These helpers produce [ProviderDefinedToolSpec] instances that can
  /// be passed via [LanguageModelCallOptions.callTools] for Responses
  /// calls. They mirror the `openai.tools.*` provider-defined tools
  /// from the Vercel AI SDK (web search, file search, code interpreter,
  /// image generation).
  OpenAIProviderDefinedTools get providerTools =>
      const OpenAIProviderDefinedTools();

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

  /// Internal helper to create an [OpenAIConfig] for a given model.
  ///
  /// This method starts from a unified [LLMConfig] (so that headers,
  /// timeouts and extensions stay in one place) and then maps it to
  /// [OpenAIConfig] via [OpenAIConfig.fromLLMConfig]. Responses API
  /// options and built-in tools are passed through extensions.
  OpenAIConfig _createOpenAIConfig({
    required String modelId,
    bool useResponsesAPI = false,
    List<OpenAIBuiltInTool>? builtInTools,
  }) {
    var baseConfig = _createLLMConfig(modelId);

    if (useResponsesAPI) {
      baseConfig =
          baseConfig.withExtension(LLMConfigKeys.useResponsesAPI, true);
    }

    if (builtInTools != null && builtInTools.isNotEmpty) {
      baseConfig =
          baseConfig.withExtension(LLMConfigKeys.builtInTools, builtInTools);
    }

    return OpenAIConfig.fromLLMConfig(baseConfig);
  }

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return openaiDefaultBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// LanguageModel wrapper for the OpenAI Responses API.
///
/// This type implements both [LanguageModel] and the full
/// [OpenAIResponsesCapability] interface so that it can be used
/// with high-level helpers (`generateTextWithModel`) and also access the
/// underlying Responses API features (background responses, lifecycle
/// management, response chaining, etc.).
class OpenAIResponsesModel implements LanguageModel, OpenAIResponsesCapability {
  final DefaultLanguageModel _model;
  final OpenAIResponses _responses;

  OpenAIResponsesModel({
    required String providerId,
    required String modelId,
    required LLMConfig config,
    required OpenAIResponses responses,
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
    List<ModelMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _responses.chatWithTools(
      messages,
      tools,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<ChatResponse> chatWithToolsBackground(
    List<ModelMessage> messages,
    List<Tool>? tools, {
    LanguageModelCallOptions? options,
  }) {
    return _responses.chatWithToolsBackground(
      messages,
      tools,
      options: options,
    );
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ModelMessage> messages, {
    List<Tool>? tools,
    LanguageModelCallOptions? options,
    CancellationToken? cancelToken,
  }) {
    return _responses.chatStream(
      messages,
      tools: tools,
      options: options,
      cancelToken: cancelToken,
    );
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
    List<ModelMessage> newMessages, {
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
    List<ModelMessage> newMessages, {
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

  /// Create an OpenAI code interpreter tool.
  ///
  /// This maps to OpenAI's `code_interpreter` Responses tool and mirrors
  /// the intent of `openai.tools.codeInterpreter` in the Vercel AI SDK.
  /// The [parameters] map is provider-specific and reserved for future
  /// extensions; most use cases can omit it.
  OpenAICodeInterpreterTool codeInterpreter({
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIBuiltInTools.codeInterpreter(
        parameters: parameters,
      );

  /// Create an OpenAI image generation tool.
  ///
  /// This maps to OpenAI's `image_generation` Responses tool. You can
  /// optionally override the [model] (for example `gpt-image-1`) and
  /// pass additional [parameters] such as size, quality, or style that
  /// the provider understands.
  OpenAIImageGenerationTool imageGeneration({
    String? model,
    Map<String, dynamic>? parameters,
  }) =>
      OpenAIBuiltInTools.imageGeneration(
        model: model,
        parameters: parameters,
      );
}

/// OpenAI provider-defined tools factory (Responses API).
///
/// This mirrors the provider-defined tools concept from the Vercel AI SDK
/// for the OpenAI Responses API. The helpers here produce
/// [ProviderDefinedToolSpec] instances that can be passed via
/// [LanguageModelCallOptions.callTools] to enable built-in tools in a
/// provider-agnostic way. The underlying Responses implementation then
/// converts these specs into native OpenAI tool configurations.
class OpenAIProviderDefinedTools {
  const OpenAIProviderDefinedTools();

  /// Provider-defined web search tool (`openai.web_search`).
  ///
  /// Arguments mirror the Vercel AI SDK web search tool:
  /// - [allowedDomains] → filters.allowedDomains
  /// - [contextSize] → searchContextSize
  /// - [location] → userLocation
  ProviderDefinedToolSpec webSearch({
    List<String>? allowedDomains,
    WebSearchContextSize? contextSize,
    WebSearchLocation? location,
  }) {
    final args = <String, dynamic>{};
    if (allowedDomains != null) args['allowedDomains'] = allowedDomains;
    if (contextSize != null) args['contextSize'] = contextSize;
    if (location != null) args['location'] = location;

    return ProviderDefinedToolSpec(
      id: 'openai.web_search',
      args: args,
    );
  }

  /// Provider-defined file search tool (`openai.file_search`).
  ///
  /// Arguments are a simplified subset of the Vercel AI SDK file search
  /// tool and map to the corresponding Responses tool configuration.
  ProviderDefinedToolSpec fileSearch({
    required List<String> vectorStoreIds,
    int? maxNumResults,
    Map<String, dynamic>? filters,
  }) {
    final args = <String, dynamic>{
      'vectorStoreIds': vectorStoreIds,
    };
    if (maxNumResults != null) args['maxNumResults'] = maxNumResults;
    if (filters != null) args['filters'] = filters;

    return ProviderDefinedToolSpec(
      id: 'openai.file_search',
      args: args,
    );
  }

  /// Provider-defined code interpreter tool (`openai.code_interpreter`).
  ///
  /// For now this only accepts an opaque [parameters] bag which is
  /// forwarded to the underlying Responses tool.
  ProviderDefinedToolSpec codeInterpreter({
    Map<String, dynamic>? parameters,
  }) {
    final args = <String, dynamic>{};
    if (parameters != null) args['parameters'] = parameters;

    return ProviderDefinedToolSpec(
      id: 'openai.code_interpreter',
      args: args,
    );
  }

  /// Provider-defined image generation tool (`openai.image_generation`).
  ///
  /// Arguments mirror the core model/parameter structure of the Vercel
  /// AI SDK image generation tool:
  /// - [model] specifies the image model (e.g. `gpt-image-1`)
  /// - [parameters] is an opaque bag for provider-specific options
  ProviderDefinedToolSpec imageGeneration({
    String? model,
    Map<String, dynamic>? parameters,
  }) {
    final args = <String, dynamic>{};
    if (model != null) args['model'] = model;
    if (parameters != null) args['parameters'] = parameters;

    return ProviderDefinedToolSpec(
      id: 'openai.image_generation',
      args: args,
    );
  }
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
///   messages: [ModelMessage.userText('Hello')],
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
