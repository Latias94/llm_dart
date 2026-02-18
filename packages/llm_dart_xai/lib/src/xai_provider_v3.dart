import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config.dart';
import '../defaults.dart';
import '../provider.dart';
import '../responses_provider.dart';

typedef XAIProviderClientFactory = OpenAIClient Function(XAIConfig config);

class XAIProviderSettings {
  final Object? apiKey;
  final String? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;
  final SearchParameters? searchParameters;
  final bool? liveSearch;

  /// Optional provider constructor override (useful for tests).
  final XAIProvider Function(XAIConfig config, {OpenAIClient? client})?
      providerFactory;

  /// Optional OpenAI client factory override (useful for tests).
  final XAIProviderClientFactory? clientFactory;

  const XAIProviderSettings({
    this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.searchParameters,
    this.liveSearch,
    this.providerFactory,
    this.clientFactory,
  });
}

/// xAI provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/xai` shape:
/// - `createXai(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model
class XAIProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final XAIProviderSettings settings;

  const XAIProviderV3(this.settings);

  XAIProvider call(String modelId) => languageModel(modelId) as XAIProvider;

  String _loadApiKey() => loadApiKey(
        apiKey: settings.apiKey,
        apiKeyParameterName: 'apiKey',
        environmentVariableName: 'XAI_API_KEY',
        description: 'xAI API key',
      );

  String _resolveBaseUrl() =>
      withoutTrailingSlash(settings.baseUrl) ??
      withoutTrailingSlash(xaiBaseUrl)!;

  ProviderOptions _providerOptions({
    String? imageModel,
    String? videoModel,
  }) {
    final options = <String, dynamic>{};

    final headers = settings.headers;
    if (headers != null && headers.isNotEmpty) {
      options['headers'] = headers;
    }

    final searchParameters = settings.searchParameters;
    if (searchParameters != null) {
      options['searchParameters'] = searchParameters.toJson();
    }

    final liveSearch = settings.liveSearch;
    if (liveSearch != null) {
      options['liveSearch'] = liveSearch;
    }

    if (imageModel != null) options['imageModel'] = imageModel;
    if (videoModel != null) options['videoModel'] = videoModel;

    if (options.isEmpty) return const {};
    return {
      'xai': options,
    };
  }

  XAIConfig _configForModel(
    String modelId, {
    String? imageModel,
    String? videoModel,
  }) {
    final apiKey = _loadApiKey();
    final baseUrl = _resolveBaseUrl();

    final providerOptions = _providerOptions(
      imageModel: imageModel,
      videoModel: videoModel,
    );

    return XAIConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      imageModel: imageModel ?? xaiDefaultImageModel,
      videoModel: videoModel ?? xaiDefaultVideoModel,
      timeout: settings.timeout,
      searchParameters: settings.searchParameters?.copyWith(),
      liveSearch: settings.liveSearch,
      originalConfig: LLMConfig(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: modelId,
        timeout: settings.timeout,
        providerOptions: providerOptions,
      ),
    );
  }

  XAIProvider _newProviderWithClient(XAIConfig config) {
    final clientFactory = settings.clientFactory;
    final providerFactory = settings.providerFactory;

    if (clientFactory == null && providerFactory == null) {
      return XAIProvider(config);
    }

    final client = clientFactory?.call(config);
    if (providerFactory != null) {
      return providerFactory(config, client: client);
    }
    return XAIProvider(config, client: client);
  }

  @override
  ChatCapability languageModel(String modelId) {
    return _newProviderWithClient(_configForModel(modelId));
  }

  @override
  EmbeddingCapability embeddingModel(String modelId) {
    return _newProviderWithClient(_configForModel(modelId));
  }

  @override
  ImageGenerationCapability imageModel(String modelId) {
    return _newProviderWithClient(
      _configForModel(
        xaiDefaultModel,
        imageModel: modelId,
      ),
    );
  }

  /// Alias for `imageModel(...)` (upstream parity).
  ImageGenerationCapability image(String modelId) => imageModel(modelId);

  @override
  ExperimentalVideoGenerationCapability videoModel(String modelId) {
    return _newProviderWithClient(
      _configForModel(
        xaiDefaultModel,
        videoModel: modelId,
      ),
    );
  }

  /// Alias for `videoModel(...)` (upstream parity).
  ExperimentalVideoGenerationCapability video(String modelId) =>
      videoModel(modelId);

  /// Creates a Responses API model (agentic tool calling).
  ChatCapability responsesModel(
    String modelId, {
    bool? store,
    String? previousResponseId,
  }) {
    final apiKey = _loadApiKey();
    final baseUrl = _resolveBaseUrl();

    final options = <String, dynamic>{
      if (store != null) 'store': store,
      if (previousResponseId != null) 'previousResponseId': previousResponseId,
      if (settings.headers != null && settings.headers!.isNotEmpty)
        'headers': settings.headers,
    };

    final llmConfig = LLMConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      timeout: settings.timeout,
      providerOptions: options.isEmpty
          ? const {}
          : {
              'xai.responses': options,
            },
    );

    return XAIResponsesProvider(llmConfig);
  }

  /// Alias for `responsesModel(...)` (upstream parity).
  ChatCapability responses(
    String modelId, {
    bool? store,
    String? previousResponseId,
  }) =>
      responsesModel(
        modelId,
        store: store,
        previousResponseId: previousResponseId,
      );
}
