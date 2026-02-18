import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/audio.dart';
import 'package:llm_dart_openai_compatible/client.dart';
import 'package:llm_dart_openai_compatible/llm_dart_openai_compatible.dart';
import 'package:llm_dart_openai_compatible/openai_request_config.dart';
import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../config.dart';
import '../defaults.dart';
import '../provider.dart';

typedef GroqProviderClientFactory = OpenAIClient Function(
  OpenAIRequestConfig config,
);

class GroqProviderSettings {
  final Object? apiKey;
  final String? baseUrl;
  final Map<String, String>? headers;
  final Duration? timeout;

  /// Optional Groq provider constructor override (useful for tests).
  final GroqProvider Function(GroqConfig config)? providerFactory;

  /// Optional OpenAI client factory override (useful for tests).
  final GroqProviderClientFactory? clientFactory;

  const GroqProviderSettings({
    this.apiKey,
    this.baseUrl,
    this.headers,
    this.timeout,
    this.providerFactory,
    this.clientFactory,
  });
}

/// Groq provider factory (AI SDK v3 style).
///
/// Mirrors the upstream `@ai-sdk/groq` shape:
/// - `createGroq(...)` returns a callable provider object
/// - calling the provider with a model id returns a language model
class GroqProviderV3 with ProviderV3Defaults implements ProviderV3 {
  final GroqProviderSettings settings;

  const GroqProviderV3(this.settings);

  GroqProvider call(String modelId) => languageModel(modelId) as GroqProvider;

  String _loadApiKey() => loadApiKey(
        apiKey: settings.apiKey,
        apiKeyParameterName: 'apiKey',
        environmentVariableName: 'GROQ_API_KEY',
        description: 'Groq',
      );

  String _resolveBaseUrl() =>
      withoutTrailingSlash(settings.baseUrl) ??
      withoutTrailingSlash(groqBaseUrl)!;

  Map<String, Map<String, dynamic>> _providerOptions() {
    final headers = settings.headers;
    if (headers == null || headers.isEmpty) return const {};
    return {
      'groq': {
        'headers': headers,
      },
    };
  }

  GroqConfig _configForModel(String modelId) {
    final apiKey = _loadApiKey();
    final baseUrl = _resolveBaseUrl();

    final options = _providerOptions();

    return GroqConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      timeout: settings.timeout,
      originalConfig: LLMConfig(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: modelId,
        timeout: settings.timeout,
        providerOptions: options.isEmpty ? const {} : options,
      ),
    );
  }

  GroqProvider _newProvider(GroqConfig config) {
    final factory = settings.providerFactory;
    if (factory == null) return GroqProvider(config);
    return factory(config);
  }

  OpenAIClient _newClient(OpenAIRequestConfig config) {
    final factory = settings.clientFactory;
    if (factory == null) return OpenAIClient(config);
    return factory(config);
  }

  OpenAICompatibleConfig _openAIConfigForModel(String modelId) {
    final apiKey = _loadApiKey();
    final baseUrl = _resolveBaseUrl();

    final llmConfig = LLMConfig(
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: modelId,
      timeout: settings.timeout,
      providerOptions: _providerOptions(),
    );

    return OpenAICompatibleConfig.fromLLMConfig(
      llmConfig,
      providerId: 'groq',
      providerName: 'Groq',
    );
  }

  @override
  ChatCapability languageModel(String modelId) {
    return _newProvider(_configForModel(modelId));
  }

  @override
  SpeechToTextCapability transcriptionModel(String modelId) {
    final config = _openAIConfigForModel(modelId);
    final client = _newClient(config);
    return _GroqTranscriptionModel(
      OpenAIStyleAudio(client, config),
      modelId: modelId,
    );
  }
}

class _GroqTranscriptionModel
    implements
        SpeechToTextCapability,
        SpeechToTextCallOptionsCapability,
        AudioTranslationCapability,
        AudioTranslationCallOptionsCapability,
        TranscriptionLanguageListingCapability {
  final OpenAIStyleAudio _audio;
  final String _modelId;

  _GroqTranscriptionModel(this._audio, {required String modelId})
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

