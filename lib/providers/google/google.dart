// The Google provider facade uses ChatMessage in examples and helper
// methods to stay compatible with the legacy chat surface. New code
// should prefer ModelMessage + ChatContentPart with prompt-first APIs.
// ignore_for_file: deprecated_member_use

/// Modular Google Provider
///
/// This library provides a modular implementation of the Google provider
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
/// import 'package:llm_dart/providers/google/google.dart';
///
/// final provider = GoogleProvider(GoogleConfig(
///   apiKey: 'your-api-key',
///   model: 'gemini-1.5-flash',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
/// ```
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_google/llm_dart_google.dart'
    show
        GoogleConfig,
        GoogleClient,
        GoogleProvider,
        GoogleChat,
        GoogleEmbeddings,
        GoogleImages,
        SafetySetting;
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show createProviderDefinedExecutableTool;

/// Public Google provider surface re-export.
///
/// This mirrors the primary Google provider types while keeping internal
/// implementation details (like HTTP strategies) in the sub-package.
export 'package:llm_dart_google/llm_dart_google.dart'
    show
        // Core config / client / provider
        GoogleConfig,
        GoogleClient,
        GoogleProvider,

        // Chat / embeddings / images
        GoogleChat,
        GoogleChatResponse,
        GoogleEmbeddings,
        GoogleImages,

        // Safety & harm configuration
        SafetySetting,
        HarmCategory,
        HarmBlockThreshold,

        // Files API
        GoogleFilesClient,
        GoogleFile;

// Builder APIs for configuring Google via LLMBuilder.
export 'builder.dart';

const _defaultBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/';

/// Google Generative AI provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `GoogleGenerativeAIProviderSettings` in the
/// Vercel AI SDK while using Dart naming conventions.
class GoogleGenerativeAIProviderSettings {
  /// API key for authenticating requests.
  final String apiKey;

  /// Base URL for the Google Generative AI API.
  ///
  /// Defaults to `https://generativelanguage.googleapis.com/v1beta/`.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `google.generative-ai`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const GoogleGenerativeAIProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// Google Generative AI model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createGoogleGenerativeAI` in
/// the Vercel AI SDK. It returns [LanguageModel] instances and capability
/// interfaces that can be used with high-level helpers.
class GoogleGenerativeAI
    implements
        LanguageModelProviderFactory,
        EmbeddingModelProviderFactory,
        ImageModelProviderFactory {
  final GoogleGenerativeAIProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  GoogleGenerativeAI(GoogleGenerativeAIProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        ),
        _providerName = settings.name ?? 'google';

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  @override
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text generation.
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GoogleConfig.fromLLMConfig(llmConfig);
    final client = GoogleClient(config);
    final chat = GoogleChat(client, config);

    return DefaultLanguageModel(
      providerId: _providerName,
      modelId: modelId,
      config: llmConfig,
      chat: chat,
    );
  }

  /// Create an embeddings model.
  EmbeddingCapability embedding(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GoogleConfig.fromLLMConfig(llmConfig);
    final client = GoogleClient(config);
    return GoogleEmbeddings(client, config);
  }

  /// Alias for [embedding] to mirror the Vercel AI SDK.
  EmbeddingCapability textEmbedding(String modelId) => embedding(modelId);

  /// Alias for [embedding] to mirror the Vercel AI SDK.
  @override
  EmbeddingCapability textEmbeddingModel(String modelId) => embedding(modelId);

  /// Create an image generation model.
  ImageGenerationCapability image(String modelId) => imageModel(modelId);

  /// Alias for [image] to mirror the Vercel AI SDK.
  @override
  ImageGenerationCapability imageModel(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = GoogleConfig.fromLLMConfig(llmConfig);
    final client = GoogleClient(config);
    return GoogleImages(client, config);
  }

  /// Google provider-defined tools facade.
  ///
  /// This mirrors the `google.tools` namespace from the Vercel AI SDK
  /// for the subset of tools that are implemented in this Dart port.
  GoogleTools get tools => const GoogleTools();

  /// Provider-defined tools factory for Google / Gemini.
  ///
  /// These helpers create [ProviderDefinedToolSpec] instances that can
  /// be passed via [LanguageModelCallOptions.callTools] to enable
  /// Gemini grounding, File Search, Code Execution and Vertex RAG Store
  /// features in a Vercel AI SDK-compatible way.
  GoogleProviderDefinedTools get providerTools =>
      const GoogleProviderDefinedTools();

  /// Build an executable web search tool that automatically calls Google.
  ///
  /// This helper constructs an [ExecutableTool] whose schema comes from
  /// [tools.webSearch] and whose execution logic:
  /// - Calls the Google Gemini chat endpoint with unified [WebSearchConfig]
  ///   enabled so that the model can perform real-time web search via
  ///   Google Search grounding.
  /// - Returns a JSON object `{ "query": string, "answer": string }` and
  ///   includes grounding metadata when available.
  ///
  /// This mirrors the intent of the `google.tools.googleSearch` helper
  /// in the Vercel AI SDK but is implemented client-side using the
  /// existing Google chat integration.
  ExecutableTool webSearchTool({
    required String modelId,
    WebSearchConfig? webSearchConfig,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
  }) {
    final schema = tools.webSearch();

    return createProviderDefinedExecutableTool<Map<String, dynamic>,
        Map<String, dynamic>>(
      schema: schema,
      execute: (args) async {
        final rawQuery = args['query'];
        final query = rawQuery is String ? rawQuery : '';

        if (query.trim().isEmpty) {
          return {
            'query': query,
            'answer': '',
            'error': 'Empty query for Google web_search tool.',
          };
        }

        // Start from the unified LLMConfig used by this provider so that
        // headers, timeouts and other extensions stay consistent.
        var llmConfig = _createLLMConfig(modelId).copyWith(
          maxTokens: maxTokens,
          temperature: temperature,
          systemPrompt: systemPrompt,
        );

        final effectiveWebSearchConfig = webSearchConfig ??
            const WebSearchConfig(
              searchType: WebSearchType.web,
            );

        llmConfig = llmConfig
            .withExtension(LLMConfigKeys.webSearchEnabled, true)
            .withExtension(
                LLMConfigKeys.webSearchConfig, effectiveWebSearchConfig);

        final googleConfig = GoogleConfig.fromLLMConfig(llmConfig);
        final client = GoogleClient(googleConfig);
        final chat = GoogleChat(client, googleConfig);

        final messages = <ModelMessage>[
          ModelMessage(
            role: ChatRole.user,
            parts: <ChatContentPart>[
              TextContentPart(query),
            ],
          ),
        ];

        final response = await chat.chatPrompt(messages);
        final text = response.text ?? '';
        final metadata = response.metadata;

        final result = <String, dynamic>{
          'query': query,
          'answer': text,
        };

        // Surface grounding metadata when web search is enabled so that
        // callers can inspect citations and retrieval details.
        if (metadata != null) {
          final grounding = metadata['groundingMetadata'];
          if (grounding != null) {
            result['groundingMetadata'] = grounding;
          }

          final urlContext = metadata['urlContextMetadata'];
          if (urlContext != null) {
            result['urlContextMetadata'] = urlContext;
          }
        }

        return result;
      },
      decodeArgs: (raw) => raw,
      encodeResult: (out) => out,
    );
  }

  LLMConfig _createLLMConfig(String modelId) {
    final headers = <String, String>{};

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

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return _defaultBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// Google provider-defined tools factory.
///
/// This mirrors the provider-defined tools concept from the Vercel AI SDK.
/// The methods on this class create [ProviderDefinedToolSpec] instances
/// that can be passed via [LanguageModelCallOptions.callTools] when
/// calling a model. The Google provider will interpret these specs and
/// map them to native Gemini grounding / File Search / Code Execution
/// tools in the request payload.
class GoogleProviderDefinedTools {
  const GoogleProviderDefinedTools();

  /// Provider-defined Google Search grounding tool.
  ///
  /// This corresponds to the `google.google_search` provider-defined tool
  /// in the Vercel AI SDK. The [mode] and [dynamicThreshold] arguments
  /// map to dynamic retrieval configuration for older Gemini models
  /// (e.g. `googleSearchRetrieval.dynamicRetrievalConfig`).
  ProviderDefinedToolSpec googleSearch({
    String? mode,
    double? dynamicThreshold,
  }) {
    final args = <String, dynamic>{};
    if (mode != null) args['mode'] = mode;
    if (dynamicThreshold != null) args['dynamicThreshold'] = dynamicThreshold;

    return ProviderDefinedToolSpec(
      id: 'google.google_search',
      args: args,
    );
  }

  /// Provider-defined URL context tool for Gemini.
  ///
  /// This maps to the `google.url_context` provider-defined tool in the
  /// Vercel AI SDK and enables URL-based grounding for supported models.
  ProviderDefinedToolSpec urlContext() {
    return const ProviderDefinedToolSpec(
      id: 'google.url_context',
    );
  }

  /// Provider-defined File Search tool for Gemini 2.5.
  ///
  /// This corresponds to `google.file_search` in the Vercel AI SDK and
  /// configures Gemini File Search with one or more File Search stores
  /// and optional metadata filters.
  ProviderDefinedToolSpec fileSearch({
    required List<String> fileSearchStoreNames,
    int? topK,
    String? metadataFilter,
  }) {
    final args = <String, dynamic>{
      'fileSearchStoreNames': fileSearchStoreNames,
    };
    if (topK != null) args['topK'] = topK;
    if (metadataFilter != null) args['metadataFilter'] = metadataFilter;

    return ProviderDefinedToolSpec(
      id: 'google.file_search',
      args: args,
    );
  }

  /// Provider-defined Code Execution tool for Gemini 2.x.
  ///
  /// This maps to `google.code_execution` in the Vercel AI SDK and
  /// enables Gemini Code Execution for supported models.
  ProviderDefinedToolSpec codeExecution() {
    return const ProviderDefinedToolSpec(
      id: 'google.code_execution',
    );
  }

  /// Provider-defined Vertex RAG Store tool.
  ///
  /// This corresponds to `google.vertex_rag_store` in the Vercel AI SDK
  /// and configures Retrieval-Augmented Generation against a Vertex
  /// RAG Store corpus.
  ProviderDefinedToolSpec vertexRagStore({
    required String ragCorpus,
    int? topK,
  }) {
    final args = <String, dynamic>{
      'ragCorpus': ragCorpus,
    };
    if (topK != null) args['topK'] = topK;

    return ProviderDefinedToolSpec(
      id: 'google.vertex_rag_store',
      args: args,
    );
  }
}

/// Google provider-defined tools facade.
///
/// This mirrors the `google.tools` namespace from the Vercel AI SDK for
/// the subset of tools that are supported in this Dart port. For now we
/// expose a schema helper for a unified `web_search` tool that can be
/// turned into an [ExecutableTool] via [GoogleGenerativeAI.webSearchTool]
/// or [createProviderDefinedExecutableTool].
class GoogleTools {
  const GoogleTools();

  /// Web search tool schema for Google / Gemini.
  ///
  /// Returns a [Tool] with:
  /// - name: `web_search`
  /// - parameters: `{ query: string }`
  ///
  /// This is intended to be used with [ExecutableTool] / agents when
  /// you want the model to request web searches via a unified schema.
  Tool webSearch() {
    return Tool.function(
      name: 'web_search',
      description:
          'Search the web using Google Gemini and Google Search grounding.',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: {
          'query': ParameterProperty(
            propertyType: 'string',
            description: 'Search query text.',
          ),
        },
        required: const ['query'],
      ),
    );
  }

  /// URL context tool schema for Google / Gemini.
  ///
  /// This mirrors the intent of `google.tools.urlContext` in the
  /// Vercel AI SDK: it gives the model access to web pages via
  /// Google\'s URL context grounding feature. The tool itself has
  /// no input parameters; relevant URLs are taken from the prompt.
  Tool urlContext() {
    return Tool.function(
      name: 'url_context',
      description:
          'Enable URL-based grounding so the model can retrieve content from web pages.',
      parameters: const ParametersSchema(
        schemaType: 'object',
        properties: <String, ParameterProperty>{},
        required: <String>[],
      ),
    );
  }

  /// File Search tool schema for Google / Gemini.
  ///
  /// This is inspired by `google.tools.fileSearch` from the Vercel
  /// AI SDK. It describes a tool that configures Gemini File Search
  /// with one or more File Search store names and optional filters.
  ///
  /// Note: In this Dart port, File Search is primarily controlled via
  /// [GoogleLLMBuilder.fileSearch] / [GoogleConfig.fileSearchConfig].
  /// This schema helper is intended for agent-style tool use where
  /// you may want the model to request file search operations and
  /// handle them via a custom [ExecutableTool].
  Tool fileSearch() {
    return Tool.function(
      name: 'file_search',
      description:
          'Retrieve knowledge from Gemini File Search stores for RAG-style queries.',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: <String, ParameterProperty>{
          'fileSearchStoreNames': ParameterProperty(
            propertyType: 'array',
            description:
                'The names of the file_search_stores to retrieve from. Example: `fileSearchStores/my-file-search-store-123`.',
            items: ParameterProperty(
              propertyType: 'string',
              description: 'Fully-qualified File Search store resource name.',
            ),
          ),
          'topK': ParameterProperty(
            propertyType: 'integer',
            description:
                'The number of file search retrieval chunks to retrieve.',
          ),
          'metadataFilter': ParameterProperty(
            propertyType: 'string',
            description:
                'Metadata filter to apply to the file search retrieval documents. See https://google.aip.dev/160 for the syntax.',
          ),
        },
        required: const ['fileSearchStoreNames'],
      ),
    );
  }

  /// Code execution tool schema for Google / Gemini.
  ///
  /// This mirrors `google.tools.codeExecution` from the Vercel AI SDK
  /// and describes a tool that lets the model generate and run code
  /// (typically Python) via Gemini\'s Code Execution feature.
  ///
  /// Note: Enabling actual server-side code execution is done via
  /// [GoogleLLMBuilder.enableCodeExecution] / [GoogleConfig.codeExecutionEnabled].
  Tool codeExecution() {
    return Tool.function(
      name: 'code_execution',
      description:
          'Generate and run code snippets using Gemini Code Execution.',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: <String, ParameterProperty>{
          'language': ParameterProperty(
            propertyType: 'string',
            description: 'Programming language of the code snippet.',
          ),
          'code': ParameterProperty(
            propertyType: 'string',
            description: 'Source code to execute.',
          ),
        },
        required: const ['language', 'code'],
      ),
    );
  }

  /// Vertex RAG Store tool schema for Google / Gemini (Vertex).
  ///
  /// This corresponds to `google.tools.vertexRagStore` in the Vercel
  /// AI SDK and describes a tool that allows the model to perform
  /// Retrieval-Augmented Generation (RAG) against a Vertex RAG Store.
  ///
  /// Note: This Dart port does not yet wire this schema to the Vertex
  /// RAG Store API. It is exposed so that agents can use a consistent
  /// tool contract and you can implement the execution logic via an
  /// [ExecutableTool] where needed.
  Tool vertexRagStore() {
    return Tool.function(
      name: 'vertex_rag_store',
      description:
          'Perform RAG searches against a Vertex RAG Store corpus using Gemini.',
      parameters: ParametersSchema(
        schemaType: 'object',
        properties: <String, ParameterProperty>{
          'ragCorpus': ParameterProperty(
            propertyType: 'string',
            description:
                'RagCorpus resource name, e.g. projects/{project}/locations/{location}/ragCorpora/{rag_corpus}.',
          ),
          'topK': ParameterProperty(
            propertyType: 'integer',
            description:
                'The number of top contexts to retrieve from the RAG Store.',
          ),
        },
        required: const ['ragCorpus'],
      ),
    );
  }
}

/// Create a Google Generative AI model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final google = createGoogleGenerativeAI(
///   apiKey: 'AIza-...',
/// );
///
/// final model = google.chat('gemini-1.5-flash');
/// final result = await generateTextWithModel(
///   model: model,
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
GoogleGenerativeAI createGoogleGenerativeAI({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return GoogleGenerativeAI(
    GoogleGenerativeAIProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createGoogleGenerativeAI] to mirror the default `google`
/// export from the Vercel AI SDK.
GoogleGenerativeAI google({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createGoogleGenerativeAI(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

/// Create a Google provider with default configuration
GoogleProvider createGoogleProvider({
  required String apiKey,
  String? model,
  String? baseUrl,
  int? maxTokens,
  double? temperature,
  String? systemPrompt,
  Duration? timeout,
  double? topP,
  int? topK,
  ReasoningEffort? reasoningEffort,
  int? thinkingBudgetTokens,
  bool? includeThoughts,
  bool? enableImageGeneration,
  List<String>? responseModalities,
  List<SafetySetting>? safetySettings,
  int? maxInlineDataSize,
  int? candidateCount,
  List<String>? stopSequences,
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  // Use GoogleConfig defaults for baseUrl/model/maxInlineDataSize and then
  // apply caller overrides via copyWith to avoid duplicating constants
  // at this top level.
  var config = GoogleConfig(apiKey: apiKey);
  config = config.copyWith(
    model: model,
    baseUrl: baseUrl,
    maxTokens: maxTokens,
    temperature: temperature,
    systemPrompt: systemPrompt,
    timeout: timeout,
    topP: topP,
    topK: topK,
    reasoningEffort: reasoningEffort,
    thinkingBudgetTokens: thinkingBudgetTokens,
    includeThoughts: includeThoughts,
    enableImageGeneration: enableImageGeneration,
    responseModalities: responseModalities,
    safetySettings: safetySettings,
    maxInlineDataSize: maxInlineDataSize,
    candidateCount: candidateCount,
    stopSequences: stopSequences,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );

  return GoogleProvider(config);
}

/// Create a Google provider for chat
GoogleProvider createGoogleChatProvider({
  required String apiKey,
  String model = 'gemini-1.5-flash',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Google provider for reasoning tasks
GoogleProvider createGoogleReasoningProvider({
  required String apiKey,
  String model = 'gemini-2.0-flash-thinking-exp',
  String? systemPrompt,
  int? thinkingBudgetTokens,
  bool includeThoughts = true,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    thinkingBudgetTokens: thinkingBudgetTokens,
    includeThoughts: includeThoughts,
  );
}

/// Create a Google provider for vision tasks
GoogleProvider createGoogleVisionProvider({
  required String apiKey,
  String model = 'gemini-1.5-pro',
  String? systemPrompt,
  double? temperature,
  int? maxTokens,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    systemPrompt: systemPrompt,
    temperature: temperature,
    maxTokens: maxTokens,
  );
}

/// Create a Google provider for image generation
GoogleProvider createGoogleImageGenerationProvider({
  required String apiKey,
  String model = 'gemini-1.5-pro',
  List<String>? responseModalities,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    enableImageGeneration: true,
    responseModalities: responseModalities ?? ['TEXT', 'IMAGE'],
  );
}

/// Create a Google provider for embeddings
GoogleProvider createGoogleEmbeddingProvider({
  required String apiKey,
  String model = 'text-embedding-004',
  String? embeddingTaskType,
  String? embeddingTitle,
  int? embeddingDimensions,
}) {
  return createGoogleProvider(
    apiKey: apiKey,
    model: model,
    embeddingTaskType: embeddingTaskType,
    embeddingTitle: embeddingTitle,
    embeddingDimensions: embeddingDimensions,
  );
}
