// The xAI provider facade demonstrates usage with ChatMessage in
// its examples for backwards compatibility. New code should prefer
// ModelMessage + ChatContentPart and the model-centric helpers.
// ignore_for_file: deprecated_member_use

/// Modular xAI Provider
///
/// This library provides a modular implementation of the xAI provider
/// following the same architecture pattern as the OpenAI provider.
///
/// **Key Features:**
/// - Grok models with real-time search capabilities
/// - Reasoning and thinking support
/// - Modular architecture for easy maintenance
/// - Support for structured outputs
/// - Search parameters for web and news sources
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/xai/xai.dart';
///
/// final provider = XAIProvider(XAIConfig(
///   apiKey: 'your-api-key',
///   model: 'grok-3',
/// ));
///
/// // Use chat capability
/// final response = await provider.chat(messages);
///
/// // Use search with Grok
/// final searchConfig = XAIConfig(
///   apiKey: 'your-api-key',
///   model: 'grok-3',
///   searchParameters: SearchParameters(
///     mode: 'auto',
///     sources: [SearchSource(sourceType: 'web')],
///   ),
/// );
/// final searchProvider = XAIProvider(searchConfig);
/// final searchResponse = await searchProvider.chat([
///   ChatMessage.user('What are the latest developments in AI?')
/// ]);
/// ```
library;

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_xai/llm_dart_xai.dart' as xai_impl;
import 'config.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'chat.dart';
export 'embeddings.dart';

const _defaultBaseUrl = 'https://api.x.ai/v1/';

@Deprecated(
  'Use XAIConfig from package:llm_dart_xai/llm_dart_xai.dart instead. '
  'This alias exists only for backwards compatibility and will be '
  'removed in a future release.',
)
// Backwards-compatible alias for the xAI configuration type.
typedef XAIConfig = xai_impl.XAIConfig;

@Deprecated(
  'Use XAIProvider from package:llm_dart_xai/llm_dart_xai.dart instead. '
  'This alias exists only for backwards compatibility and will be '
  'removed in a future release.',
)
// Backwards-compatible alias for the xAI provider type.
typedef XAIProvider = xai_impl.XAIProvider;

/// Create an xAI provider with default settings
xai_impl.XAIProvider createXAIProvider({
  required String apiKey,
  String model = 'grok-3',
  String baseUrl = 'https://api.x.ai/v1/',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  SearchParameters? searchParameters,
  bool? liveSearch,
}) {
  final config = xai_impl.XAIConfig(
    apiKey: apiKey,
    model: model,
    baseUrl: baseUrl,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    searchParameters: searchParameters,
    liveSearch: liveSearch,
  );

  return xai_impl.XAIProvider(config);
}

/// Create an xAI provider with search capabilities
xai_impl.XAIProvider createXAISearchProvider({
  required String apiKey,
  String model = 'grok-3',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  String searchMode = 'auto',
  List<SearchSource>? sources,
  int? maxSearchResults,
  String? fromDate,
  String? toDate,
}) {
  final searchParams = SearchParameters(
    mode: searchMode,
    sources: sources ?? [const SearchSource(sourceType: 'web')],
    maxSearchResults: maxSearchResults,
    fromDate: fromDate,
    toDate: toDate,
  );

  final config = xai_impl.XAIConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    searchParameters: searchParams,
    liveSearch: true, // Explicitly enable live search
  );

  return xai_impl.XAIProvider(config);
}

/// Create an xAI provider with Live Search enabled
///
/// This is a convenience function that enables Live Search with default web search settings.
/// Live Search allows Grok models to access real-time information from the web.
///
/// Example:
/// ```dart
/// final provider = createXAILiveSearchProvider(
///   apiKey: 'your-api-key',
///   model: 'grok-3',
///   maxSearchResults: 5,
/// );
///
/// final response = await provider.chat([
///   ChatMessage.user('What are the latest developments in AI?')
/// ]);
/// ```
xai_impl.XAIProvider createXAILiveSearchProvider({
  required String apiKey,
  String model = 'grok-3',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
  int? maxSearchResults,
  List<String>? excludedWebsites,
}) {
  final config = xai_impl.XAIConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
    liveSearch: true,
    searchParameters: SearchParameters.webSearch(
      maxResults: maxSearchResults,
      excludedWebsites: excludedWebsites,
    ),
  );

  return xai_impl.XAIProvider(config);
}

/// Create an xAI provider for Grok Vision
xai_impl.XAIProvider createGrokVisionProvider({
  required String apiKey,
  String model = 'grok-vision-beta',
  double? temperature,
  int? maxTokens,
  String? systemPrompt,
}) {
  final config = xai_impl.XAIConfig(
    apiKey: apiKey,
    model: model,
    temperature: temperature,
    maxTokens: maxTokens,
    systemPrompt: systemPrompt,
  );

  return xai_impl.XAIProvider(config);
}

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
    final config = xai_impl.XAIConfig.fromLLMConfig(llmConfig);
    final client = xai_impl.XAIClient(config);
    final chat = xai_impl.XAIChat(client, config);

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
    final config = xai_impl.XAIConfig.fromLLMConfig(llmConfig);
    final client = xai_impl.XAIClient(config);
    return xai_impl.XAIEmbeddings(client, config);
  }

  /// Alias for [embedding] to mirror the Vercel AI SDK and support the
  /// registry embedding factory interface.
  @override
  EmbeddingCapability textEmbeddingModel(String modelId) => embedding(modelId);

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

/// Create an XAI model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final xai = createXAI(
///   apiKey: 'xai-...',
/// );
///
/// final model = xai.chat('grok-3');
/// final result = await generateTextWithModel(
///   model: model,
///   messages: [ChatMessage.user('Hello')],
/// );
/// ```
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
