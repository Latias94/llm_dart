import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import 'audio.dart';
import 'client.dart';
import 'embeddings.dart';
import 'images.dart';
import 'openai_compatible_config.dart';
import 'openai_request_config.dart';
import 'provider.dart';

typedef OpenAICompatibleProviderClientFactory = OpenAIClient Function(
  OpenAIRequestConfig config,
);

class OpenAICompatibleProviderSettings {
  /// Base URL for the API calls.
  final String baseUrl;

  /// Provider name/id used in `providerMetadata` namespaces.
  final String name;

  /// Optional API key for authenticating requests.
  ///
  /// When null, no Authorization header is added by default.
  final Object? apiKey;

  /// Optional custom headers to include in requests.
  final Map<String, String>? headers;

  /// Optional custom URL query parameters to include in request URLs.
  ///
  /// This is applied via `LLMConfig.providerOptions[<name>]['queryParams']`
  /// so it stays compatible with the existing OpenAI client implementation.
  final Map<String, String>? queryParams;

  /// Optional request timeout.
  final Duration? timeout;

  /// Optional endpoint prefix (path prefix) applied before all endpoints.
  ///
  /// Example: `openai` => `openai/chat/completions`.
  final String? endpointPrefix;

  /// Include usage information in streaming responses.
  final bool? includeUsage;

  /// Whether the provider supports structured outputs in chat models.
  final bool? supportsStructuredOutputs;

  /// Optional OpenAI client factory override (useful for tests).
  final OpenAICompatibleProviderClientFactory? clientFactory;

  const OpenAICompatibleProviderSettings({
    required this.baseUrl,
    required this.name,
    this.apiKey,
    this.headers,
    this.queryParams,
    this.timeout,
    this.endpointPrefix,
    this.includeUsage,
    this.supportsStructuredOutputs,
    this.clientFactory,
  });
}

/// OpenAI-compatible provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/openai-compatible` shape:
/// - `createOpenAICompatible(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model
class OpenAICompatibleProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final OpenAICompatibleProviderSettings settings;

  static const Set<LLMCapability> _bestEffortCapabilities = {
    LLMCapability.chat,
    LLMCapability.streaming,
    LLMCapability.toolCalling,
    LLMCapability.embedding,
  };

  const OpenAICompatibleProviderV3(this.settings);

  OpenAICompatibleChatProvider call(String modelId) =>
      languageModel(modelId) as OpenAICompatibleChatProvider;

  OpenAIClient _newClient(OpenAIRequestConfig config) {
    final factory = settings.clientFactory;
    if (factory == null) return OpenAIClient(config);
    return factory(config);
  }

  LLMConfig _originalConfigForModel({
    required String providerId,
    required String baseUrl,
    required String modelId,
    String? apiKey,
  }) {
    final options = <String, dynamic>{};

    final queryParams = settings.queryParams;
    if (queryParams != null && queryParams.isNotEmpty) {
      options['queryParams'] = queryParams;
    }

    final includeUsage = settings.includeUsage;
    if (includeUsage != null) options['includeUsage'] = includeUsage;

    final supportsStructuredOutputs = settings.supportsStructuredOutputs;
    if (supportsStructuredOutputs != null) {
      options['supportsStructuredOutputs'] = supportsStructuredOutputs;
    }

    return LLMConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      providerOptions: options.isEmpty ? const {} : {providerId: options},
    );
  }

  OpenAICompatibleConfig _configForModel(String modelId) {
    final name = settings.name.trim();
    if (name.isEmpty) {
      throw const InvalidArgumentError(
        argument: 'name',
        message: 'OpenAI-compatible provider name must not be empty.',
      );
    }

    final rawBaseUrl = settings.baseUrl.trim();
    if (rawBaseUrl.isEmpty) {
      throw const InvalidArgumentError(
        argument: 'baseUrl',
        message: 'OpenAI-compatible provider baseUrl must not be empty.',
      );
    }

    final baseUrl = withoutTrailingSlash(rawBaseUrl) ?? rawBaseUrl;

    final providedKey = settings.apiKey;
    if (providedKey != null && providedKey is! String) {
      throw const LoadApiKeyError(
        message: 'OpenAI-compatible API key must be a string.',
      );
    }

    final apiKey = providedKey as String?;

    final endpointPrefix = settings.endpointPrefix?.trim();
    final resolvedEndpointPrefix =
        endpointPrefix != null && endpointPrefix.isNotEmpty
            ? endpointPrefix
            : null;

    final original = _originalConfigForModel(
      providerId: name,
      baseUrl: baseUrl,
      modelId: modelId,
      apiKey: apiKey,
    );

    return OpenAICompatibleConfig(
      providerId: name,
      providerName: name,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      endpointPrefix: resolvedEndpointPrefix,
      extraHeaders: settings.headers,
      timeout: settings.timeout,
      originalConfig: original,
    );
  }

  @override
  ChatCapability languageModel(String modelId) {
    final config = _configForModel(modelId);
    final client = _newClient(config);
    return OpenAICompatibleChatEmbeddingProvider(
      client,
      config,
      _bestEffortCapabilities,
    );
  }

  @override
  EmbeddingCapability embeddingModel(String modelId) {
    final config = _configForModel(modelId);
    final client = _newClient(config);
    return OpenAIEmbeddings(client, config);
  }

  @override
  ImageGenerationCapability imageModel(String modelId) {
    final config = _configForModel(modelId);
    final client = _newClient(config);
    return OpenAIStyleImages(client, config);
  }

  @override
  SpeechToTextCapability transcriptionModel(String modelId) {
    final config = _configForModel(modelId);
    final client = _newClient(config);
    return _OpenAICompatibleTranscriptionModel(
      OpenAIStyleAudio(client, config),
      modelId: modelId,
    );
  }

  @override
  TextToSpeechCapability speechModel(String modelId) {
    final config = _configForModel(modelId);
    final client = _newClient(config);
    return _OpenAICompatibleSpeechModel(
      OpenAIStyleAudio(client, config),
      modelId: modelId,
    );
  }
}

class _OpenAICompatibleSpeechModel
    implements
        TextToSpeechCapability,
        TextToSpeechCallOptionsCapability,
        VoiceListingCapability {
  final OpenAIStyleAudio _audio;
  final String _modelId;

  _OpenAICompatibleSpeechModel(this._audio, {required String modelId})
      : _modelId = modelId;

  TTSRequest _withDefaultModel(TTSRequest request) {
    if (request.model != null && request.model!.trim().isNotEmpty) {
      return request;
    }
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
    return _audio.textToSpeech(
      _withDefaultModel(request),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<TTSResponse> textToSpeechWithCallOptions(
    TTSRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _audio.textToSpeechWithCallOptions(
      _withDefaultModel(request),
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() => _audio.getVoices();
}

class _OpenAICompatibleTranscriptionModel
    implements
        SpeechToTextCapability,
        SpeechToTextCallOptionsCapability,
        AudioTranslationCapability,
        AudioTranslationCallOptionsCapability,
        TranscriptionLanguageListingCapability {
  final OpenAIStyleAudio _audio;
  final String _modelId;

  _OpenAICompatibleTranscriptionModel(this._audio, {required String modelId})
      : _modelId = modelId;

  STTRequest _withDefaultModel(STTRequest request) {
    if (request.model != null && request.model!.trim().isNotEmpty) {
      return request;
    }
    return STTRequest(
      audioData: request.audioData,
      filePath: request.filePath,
      audioUrl: request.audioUrl,
      cloudStorageUrl: request.cloudStorageUrl,
      model: _modelId,
      language: request.language,
      format: request.format,
      includeWordTiming: request.includeWordTiming,
      includeConfidence: request.includeConfidence,
      temperature: request.temperature,
      timestampGranularity: request.timestampGranularity,
      diarize: request.diarize,
      numSpeakers: request.numSpeakers,
      tagAudioEvents: request.tagAudioEvents,
      webhook: request.webhook,
      prompt: request.prompt,
      responseFormat: request.responseFormat,
      enableLogging: request.enableLogging,
    );
  }

  AudioTranslationRequest _withDefaultModelTranslation(
    AudioTranslationRequest request,
  ) {
    if (request.model != null && request.model!.trim().isNotEmpty) {
      return request;
    }
    return AudioTranslationRequest(
      audioData: request.audioData,
      filePath: request.filePath,
      model: _modelId,
      prompt: request.prompt,
      responseFormat: request.responseFormat,
      temperature: request.temperature,
      format: request.format,
    );
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.speechToText(
      _withDefaultModel(request),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<STTResponse> speechToTextWithCallOptions(
    STTRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _audio.speechToTextWithCallOptions(
      _withDefaultModel(request),
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    CancelToken? cancelToken,
  }) {
    return _audio.translateAudio(
      _withDefaultModelTranslation(request),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<STTResponse> translateAudioWithCallOptions(
    AudioTranslationRequest request, {
    required LLMCallOptions callOptions,
    CancelToken? cancelToken,
  }) {
    return _audio.translateAudioWithCallOptions(
      _withDefaultModelTranslation(request),
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() =>
      _audio.getSupportedLanguages();
}
