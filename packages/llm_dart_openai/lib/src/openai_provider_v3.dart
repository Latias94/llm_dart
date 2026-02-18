import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config.dart';
import '../defaults.dart';
import '../provider.dart';

class OpenAIProviderSettings {
  final Object? apiKey;
  final String? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;
  final String providerId;
  final String providerName;
  final OpenAIProvider Function(OpenAIConfig config)? providerFactory;

  const OpenAIProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.providerId = 'openai',
    this.providerName = 'OpenAI',
    this.providerFactory,
  });
}

/// OpenAI provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/openai` shape:
/// - `createOpenAI(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model (Responses)
class OpenAIProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final OpenAIProviderSettings settings;

  const OpenAIProviderV3(this.settings);

  OpenAIProvider call(String modelId) =>
      languageModel(modelId) as OpenAIProvider;

  OpenAIConfig _baseConfig({
    required String modelId,
    required bool useResponsesAPI,
  }) {
    final apiKey = loadApiKey(
      apiKey: settings.apiKey,
      apiKeyParameterName: 'apiKey',
      environmentVariableName: 'OPENAI_API_KEY',
      description: 'OpenAI',
    );

    final baseUrl = settings.baseUrl?.trim().isEmpty == false
        ? settings.baseUrl!.trim()
        : null;

    return OpenAIConfig(
      providerId: settings.providerId,
      providerName: settings.providerName,
      apiKey: apiKey,
      baseUrl: baseUrl ?? openaiBaseUrl,
      model: modelId,
      extraHeaders: settings.headers,
      timeout: settings.timeout,
      useResponsesAPI: useResponsesAPI,
    );
  }

  OpenAIProvider _newProvider(OpenAIConfig config) {
    final factory = settings.providerFactory;
    if (factory == null) return OpenAIProvider(config);
    return factory(config);
  }

  @override
  ChatCapability languageModel(String modelId) {
    return _newProvider(
      _baseConfig(
        modelId: modelId,
        useResponsesAPI: true,
      ),
    );
  }

  @override
  EmbeddingCapability embeddingModel(String modelId) {
    return _newProvider(
      _baseConfig(
        modelId: modelId,
        useResponsesAPI: true,
      ),
    );
  }

  @override
  ImageGenerationCapability imageModel(String modelId) {
    return _newProvider(
      _baseConfig(
        modelId: modelId,
        useResponsesAPI: true,
      ),
    );
  }

  @override
  SpeechToTextCapability transcriptionModel(String modelId) {
    return _OpenAITranscriptionModel(
      _newProvider(
        _baseConfig(
          modelId: openaiDefaultModel,
          useResponsesAPI: true,
        ),
      ),
      modelId: modelId,
    );
  }

  @override
  TextToSpeechCapability speechModel(String modelId) {
    return _OpenAISpeechModel(
      _newProvider(
        _baseConfig(
          modelId: openaiDefaultModel,
          useResponsesAPI: true,
        ),
      ),
      modelId: modelId,
    );
  }
}

class _OpenAISpeechModel
    implements
        TextToSpeechCapability,
        TextToSpeechCallOptionsCapability,
        VoiceListingCapability {
  final OpenAIProvider _provider;
  final String _modelId;

  _OpenAISpeechModel(this._provider, {required String modelId})
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
    return _provider.textToSpeech(
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
    return _provider.textToSpeechWithCallOptions(
      _withDefaultModel(request),
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() => _provider.getVoices();
}

class _OpenAITranscriptionModel
    implements
        SpeechToTextCapability,
        SpeechToTextCallOptionsCapability,
        AudioTranslationCapability,
        AudioTranslationCallOptionsCapability,
        TranscriptionLanguageListingCapability {
  final OpenAIProvider _provider;
  final String _modelId;

  _OpenAITranscriptionModel(this._provider, {required String modelId})
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
      format: request.format,
      prompt: request.prompt,
      responseFormat: request.responseFormat,
      temperature: request.temperature,
    );
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    CancelToken? cancelToken,
  }) {
    return _provider.speechToText(
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
    return _provider.speechToTextWithCallOptions(
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
    return _provider.translateAudio(
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
    return _provider.translateAudioWithCallOptions(
      _withDefaultModelTranslation(request),
      callOptions: callOptions,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() =>
      _provider.getSupportedLanguages();
}
