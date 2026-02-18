import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config.dart';
import '../defaults.dart';
import '../provider.dart';

class GoogleProviderSettings {
  final Object? apiKey;
  final Object? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;

  /// Provider id used for reading request-side `providerOptions`.
  ///
  /// Default: `google`.
  final String providerId;

  /// Provider options namespace name used for `providerMetadata`.
  ///
  /// Default: `google`.
  final String providerOptionsName;

  /// Fallback provider ids used for reading request-side `providerOptions`.
  ///
  /// This exists to preserve backwards compatibility for renamed provider
  /// namespaces (e.g. Vertex: `google-vertex` -> `vertex`).
  final List<String> providerOptionsFallbackIds;

  /// Optional provider constructor override (useful for tests).
  final GoogleProvider Function(GoogleConfig config)? providerFactory;

  const GoogleProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.providerId = 'google',
    this.providerOptionsName = 'google',
    this.providerOptionsFallbackIds = const [],
    this.providerFactory,
  });
}

/// Google Generative AI (Gemini API) provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/google` shape:
/// - `createGoogleGenerativeAI(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model
class GoogleProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final GoogleProviderSettings settings;

  const GoogleProviderV3(this.settings);

  GoogleProvider call(String modelId) =>
      languageModel(modelId) as GoogleProvider;

  GoogleConfig _configForModel(String modelId) {
    final apiKey = loadApiKey(
      apiKey: settings.apiKey,
      apiKeyParameterName: 'apiKey',
      environmentVariableName: 'GOOGLE_GENERATIVE_AI_API_KEY',
      description: 'Google Generative AI',
    );

    final rawBaseUrl = settings.baseUrl is String
        ? (settings.baseUrl as String).trim()
        : null;

    final baseUrl = withoutTrailingSlash(
          rawBaseUrl != null && rawBaseUrl.isNotEmpty ? rawBaseUrl : null,
        ) ??
        withoutTrailingSlash(googleBaseUrl)!;

    final providerId = settings.providerId.trim().isEmpty
        ? 'google'
        : settings.providerId.trim();
    final providerOptionsName = settings.providerOptionsName.trim().isEmpty
        ? providerId
        : settings.providerOptionsName.trim();

    return GoogleConfig(
      providerId: providerId,
      providerOptionsName: providerOptionsName,
      providerOptionsFallbackIds: settings.providerOptionsFallbackIds,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      extraHeaders: settings.headers,
      timeout: settings.timeout,
    );
  }

  GoogleProvider _newProvider(GoogleConfig config) {
    final factory = settings.providerFactory;
    if (factory == null) return GoogleProvider(config);
    return factory(config);
  }

  @override
  ChatCapability languageModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );

  @override
  EmbeddingCapability embeddingModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );

  @override
  ImageGenerationCapability imageModel(String modelId) => _newProvider(
        _configForModel(modelId),
      );

  @override
  ExperimentalVideoGenerationCapability videoModel(String modelId) =>
      _newProvider(
        _configForModel(modelId),
      );

  @override
  TextToSpeechCapability speechModel(String modelId) => _GoogleSpeechModel(
        _newProvider(
          _configForModel(googleDefaultModel),
        ),
        modelId: modelId,
      );
}

class _GoogleSpeechModel
    implements
        TextToSpeechCapability,
        StreamingTextToSpeechCapability,
        VoiceListingCapability {
  final GoogleProvider _provider;
  final String _modelId;

  _GoogleSpeechModel(this._provider, {required String modelId})
      : _modelId = modelId;

  TTSRequest _withDefaultModel(TTSRequest request) {
    if (request.model != null && request.model!.trim().isNotEmpty) return request;
    return TTSRequest(
      text: request.text,
      voice: request.voice,
      model: _modelId,
      format: request.format,
      quality: request.quality,
      sampleRate: request.sampleRate,
      stability: request.stability,
      similarityBoost: request.similarityBoost,
      style: request.style,
      useSpeakerBoost: request.useSpeakerBoost,
      speed: request.speed,
      processingMode: request.processingMode,
      includeTimestamps: request.includeTimestamps,
      timestampGranularity: request.timestampGranularity,
      textNormalization: request.textNormalization,
      languageCode: request.languageCode,
      instructions: request.instructions,
      previousText: request.previousText,
      nextText: request.nextText,
      previousRequestIds: request.previousRequestIds,
      nextRequestIds: request.nextRequestIds,
      seed: request.seed,
      enableLogging: request.enableLogging,
      optimizeStreamingLatency: request.optimizeStreamingLatency,
    );
  }

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    return _provider.textToSpeech(
      _withDefaultModel(request),
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) {
    return _provider.textToSpeechStream(
      _withDefaultModel(request),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() => _provider.getVoices();
}
