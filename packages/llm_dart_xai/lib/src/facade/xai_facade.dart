import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart'
    show createProviderDefinedExecutableTool;

import '../chat/xai_chat.dart';
import '../client/xai_client.dart';
import '../config/search_parameters.dart';
import '../config/xai_config.dart';
import '../embeddings/xai_embeddings.dart';

const _defaultBaseUrl = 'https://api.x.ai/v1/';

/// XAI provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `XaiProviderSettings` in the Vercel AI SDK
/// while using Dart conventions.
class XAIProviderSettings {
  /// API key for authenticating requests.
  final String apiKey;

  /// Base URL for the xAI API.
  ///
  /// Defaults to `https://api.x.ai/v1/`.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const XAIProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
  });
}

/// XAI model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createXai` in the Vercel AI SDK.
/// It returns [LanguageModel] instances and capability interfaces that can be
/// used with high-level helpers.
class XAI
    implements LanguageModelProviderFactory, EmbeddingModelProviderFactory {
  final XAIProviderSettings _settings;
  final String _baseUrl;

  XAI(XAIProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        );

  /// Create a language model for text generation.
  ///
  /// Alias for [chat].
  @override
  LanguageModel languageModel(String modelId) => chat(modelId);

  /// Create a chat model for text generation.
  LanguageModel chat(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = XAIConfig.fromLLMConfig(llmConfig);
    final client = XAIClient(config);
    final chat = XAIChat(client, config);

    return DefaultLanguageModel(
      providerId: 'xai.chat',
      modelId: modelId,
      config: llmConfig,
      chat: chat,
    );
  }

  /// Create an embeddings model.
  EmbeddingCapability embedding(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    final config = XAIConfig.fromLLMConfig(llmConfig);
    final client = XAIClient(config);
    return XAIEmbeddings(client, config);
  }

  /// Alias for [embedding] to mirror the Vercel AI SDK and support the
  /// registry embedding factory interface.
  @override
  EmbeddingCapability textEmbeddingModel(String modelId) => embedding(modelId);

  /// xAI provider-defined tools.
  ///
  /// This mirrors the `xai.tools` namespace from the Vercel AI SDK for
  /// the subset of tools that are implemented in this Dart port.
  XAITools get tools => const XAITools();

  /// Provider-defined tools factory for xAI.
  ///
  /// These helpers create [ProviderDefinedToolSpec] instances that can
  /// be used with Responses-style integrations or future xAI-specific
  /// provider-defined tool handling. The current chat integration does
  /// not interpret these specs directly.
  XAIProviderDefinedTools get providerTools => const XAIProviderDefinedTools();

  /// Build an executable web search tool that automatically calls xAI.
  ///
  /// This helper constructs an [ExecutableTool] whose schema comes from
  /// [tools.webSearch] and whose execution logic:
  /// - Calls the xAI chat endpoint with [SearchParameters] and `liveSearch`
  ///   enabled so that Grok performs real-time web search.
  /// - Returns a JSON object `{ "query": string, "answer": string }`.
  ///
  /// This mirrors the intent of the `xai.webSearch` provider-defined tool
  /// in the Vercel AI SDK, but is implemented client-side using the
  /// existing xAI chat integration.
  ExecutableTool webSearchTool({
    required String modelId,
    SearchParameters? searchParameters,
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
            'error': 'Empty query for xAI web_search tool.',
          };
        }

        final config = XAIConfig(
          apiKey: _settings.apiKey,
          baseUrl: _baseUrl,
          model: modelId,
          temperature: temperature,
          maxTokens: maxTokens,
          systemPrompt: systemPrompt,
          searchParameters:
              searchParameters ?? SearchParameters.webSearch(maxResults: null),
        );

        final client = XAIClient(config);
        final chat = XAIChat(client, config);

        final messages = <ModelMessage>[
          ModelMessage(
            role: ChatRole.user,
            parts: <ChatContentPart>[
              TextContentPart(query),
            ],
          ),
        ];

        final response = await chat.chat(messages);
        final text = response.text ?? '';

        return <String, dynamic>{
          'query': query,
          'answer': text,
        };
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

/// xAI provider-defined tools facade.
///
/// This mirrors the `xai.tools` namespace from the Vercel AI SDK for
/// the subset of tools that are supported in this Dart port. For now
/// we expose a schema helper for the `web_search` tool; callers can
/// turn it into an [ExecutableTool] via [ProviderDefinedToolFactory]
/// when they want to provide a concrete implementation.
class XAITools {
  const XAITools();

  /// Web search tool schema for xAI.
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
      description: 'Search the web using xAI live search / Grok capabilities.',
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
}

/// xAI provider-defined tools factory.
///
/// This mirrors the `xai.web_search` / `xai.x_search` provider-defined
/// tools in the Vercel AI SDK. These specs are intended to be used with
/// Responses-style integrations; the current chat integration does not
/// yet consume them directly.
class XAIProviderDefinedTools {
  const XAIProviderDefinedTools();

  /// Provider-defined web search tool for xAI.
  ///
  /// Corresponds to the `xai.web_search` provider-defined tool ID in
  /// the Vercel AI SDK. The arguments map directly to the schema used
  /// in `web-search.ts`:
  /// - [allowedDomains]
  /// - [excludedDomains]
  /// - [enableImageUnderstanding]
  ProviderDefinedToolSpec webSearch({
    List<String>? allowedDomains,
    List<String>? excludedDomains,
    bool? enableImageUnderstanding,
  }) {
    final args = <String, dynamic>{};
    if (allowedDomains != null) args['allowedDomains'] = allowedDomains;
    if (excludedDomains != null) args['excludedDomains'] = excludedDomains;
    if (enableImageUnderstanding != null) {
      args['enableImageUnderstanding'] = enableImageUnderstanding;
    }

    return ProviderDefinedToolSpec(
      id: 'xai.web_search',
      args: args,
    );
  }

  /// Provider-defined X search tool for xAI.
  ///
  /// Corresponds to the `xai.x_search` provider-defined tool ID in the
  /// Vercel AI SDK. The arguments mirror those from `x-search.ts`:
  /// - [allowedXHandles]
  /// - [excludedXHandles]
  /// - [fromDate]
  /// - [toDate]
  /// - [enableImageUnderstanding]
  /// - [enableVideoUnderstanding]
  ProviderDefinedToolSpec xSearch({
    List<String>? allowedXHandles,
    List<String>? excludedXHandles,
    String? fromDate,
    String? toDate,
    bool? enableImageUnderstanding,
    bool? enableVideoUnderstanding,
  }) {
    final args = <String, dynamic>{};
    if (allowedXHandles != null) args['allowedXHandles'] = allowedXHandles;
    if (excludedXHandles != null) {
      args['excludedXHandles'] = excludedXHandles;
    }
    if (fromDate != null) args['fromDate'] = fromDate;
    if (toDate != null) args['toDate'] = toDate;
    if (enableImageUnderstanding != null) {
      args['enableImageUnderstanding'] = enableImageUnderstanding;
    }
    if (enableVideoUnderstanding != null) {
      args['enableVideoUnderstanding'] = enableVideoUnderstanding;
    }

    return ProviderDefinedToolSpec(
      id: 'xai.x_search',
      args: args,
    );
  }
}

/// Create an XAI model factory (Vercel AI-style).
XAI createXAI({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
}) {
  return XAI(
    XAIProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      timeout: timeout,
    ),
  );
}

/// Alias for [createXAI] to mirror the default `xai` export from
/// the Vercel AI SDK.
XAI xai({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  Duration? timeout,
}) {
  return createXAI(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    timeout: timeout,
  );
}
