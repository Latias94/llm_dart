import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_core/llm_dart_core.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioTransportClient;

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../models/chat_models.dart';
import '../../models/tool_models.dart';
import '../../models/audio_models.dart';
import '../../src/compatibility/providers/compat_provider_support.dart'
    show isCompatibilityError;
import 'audio.dart';
import 'client.dart';
import 'config.dart';
import 'models.dart';

/// ElevenLabs Provider implementation
///
/// This is the main provider class that implements audio capabilities
/// and delegates to specialized modules for different functionalities.
/// ElevenLabs specializes in text-to-speech and speech-to-text services.
class ElevenLabsProvider implements ChatCapability, AudioCapability {
  final ElevenLabsConfig config;
  final ElevenLabsClient client;
  late final ElevenLabsAudio audio;
  late final ElevenLabsModels models;
  late final modern_community.ElevenLabs _modernProvider;

  ElevenLabsProvider(this.config) : client = ElevenLabsClient(config) {
    audio = ElevenLabsAudio(client, config);
    models = ElevenLabsModels(client, config);
    _modernProvider = modern_community.ElevenLabs(
      apiKey: config.apiKey,
      baseUrl: config.baseUrl,
      transport: DioTransportClient(dio: client.dio),
    );
  }

  String get providerName => 'ElevenLabs';

  // ChatCapability implementation (not supported)
  @override
  Future<ChatResponse> chatWithTools(
    List<ChatMessage> messages,
    List<Tool>? tools, {
    TransportCancellation? cancelToken,
  }) async {
    throw const ProviderError('ElevenLabs does not support chat functionality');
  }

  @override
  Future<ChatResponse> chat(
    List<ChatMessage> messages, {
    TransportCancellation? cancelToken,
  }) async {
    return chatWithTools(messages, null, cancelToken: cancelToken);
  }

  @override
  Future<List<ChatMessage>?> memoryContents() async => null;

  @override
  Future<String> summarizeHistory(List<ChatMessage> messages) async {
    throw const ProviderError('ElevenLabs does not support chat functionality');
  }

  @override
  Stream<ChatStreamEvent> chatStream(
    List<ChatMessage> messages, {
    List<Tool>? tools,
    TransportCancellation? cancelToken,
  }) async* {
    yield ErrorEvent(
        const ProviderError('ElevenLabs does not support chat functionality'));
  }

  // AudioCapability implementation (delegated to audio module)

  @override
  Set<AudioFeature> get supportedFeatures => audio.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    if (_canUseElevenLabsSpeechBridge(request)) {
      try {
        return await _bridgeTextToSpeech(
          request,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return audio.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return audio.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    if (_canUseElevenLabsTranscriptionBridge(request)) {
      try {
        return await _bridgeSpeechToText(
          request,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return audio.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return audio.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return audio.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) async {
    return audio.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return audio.getSupportedAudioFormats();
  }

  // AudioCapability convenience methods implementation
  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await textToSpeech(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    );
    return response.audioData;
  }

  @override
  Stream<List<int>> speechStream(String text) async* {
    await for (final event in textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    final response = await speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    final response = await speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }

  @override
  Future<String> translate(List<int> audio) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromAudio(audio));
    return response.text;
  }

  @override
  Future<String> translateFile(String filePath) async {
    final response =
        await translateAudio(AudioTranslationRequest.fromFile(filePath));
    return response.text;
  }

  /// Get available models
  Future<List<Map<String, dynamic>>> getModels() async {
    return models.getModels();
  }

  /// Get user subscription info
  Future<Map<String, dynamic>> getUserInfo() async {
    return models.getUserInfo();
  }

  /// Create a new provider with updated configuration
  ElevenLabsProvider copyWith({
    String? apiKey,
    String? baseUrl,
    String? voiceId,
    String? model,
    Duration? timeout,
    double? stability,
    double? similarityBoost,
    double? style,
    bool? useSpeakerBoost,
  }) {
    final newConfig = config.copyWith(
      apiKey: apiKey,
      baseUrl: baseUrl,
      voiceId: voiceId,
      model: model,
      timeout: timeout,
      stability: stability,
      similarityBoost: similarityBoost,
      style: style,
      useSpeakerBoost: useSpeakerBoost,
    );

    return ElevenLabsProvider(newConfig);
  }

  /// Check if the provider supports a specific capability
  bool supportsCapability(Type capability) {
    if (capability == AudioCapability) return true;
    // ElevenLabs doesn't support chat
    if (capability == ChatCapability) return false;
    return false;
  }

  /// Get provider information
  Map<String, dynamic> get info => {
        'provider': providerName,
        'baseUrl': config.baseUrl,
        'supportsChat': false,
        'supportsTextToSpeech': config.supportsTextToSpeech,
        'supportsSpeechToText': config.supportsSpeechToText,
        'supportsVoiceCloning': config.supportsVoiceCloning,
        'supportsRealTimeStreaming': config.supportsRealTimeStreaming,
        'defaultVoiceId': config.defaultVoiceId,
        'defaultTTSModel': config.defaultTTSModel,
        'defaultSTTModel': config.defaultSTTModel,
        'supportedAudioFormats': config.supportedAudioFormats,
      };

  @override
  String toString() => 'ElevenLabsProvider(voice: ${config.defaultVoiceId})';

  Future<TTSResponse> _bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final model = _modernProvider.speechModel(
      request.model ?? config.defaultTTSModel,
      settings: modern_community.ElevenLabsSpeechModelSettings(
        defaultVoiceId: config.voiceId,
        stability: config.stability,
        similarityBoost: config.similarityBoost,
        style: config.style,
        useSpeakerBoost: config.useSpeakerBoost,
      ),
    );

    final result = await model.generateSpeech(
      core.SpeechGenerationRequest(
        text: request.text,
        voice: request.voice,
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
          providerOptions: modern_community.ElevenLabsSpeechOptions(
            outputFormat: _mapLegacySpeechOutputFormat(
              request.format,
              sampleRate: request.sampleRate,
            ),
            languageCode: request.languageCode,
            speed: request.speed,
            seed: request.seed,
            previousText: request.previousText,
            nextText: request.nextText,
            previousRequestIds: _takeAtMostThree(request.previousRequestIds),
            nextRequestIds: _takeAtMostThree(request.nextRequestIds),
            textNormalization:
                _toModernTextNormalization(request.textNormalization),
            enableLogging: request.enableLogging,
            optimizeStreamingLatency: request.optimizeStreamingLatency,
            stability: request.stability,
            similarityBoost: request.similarityBoost,
            style: request.style,
            useSpeakerBoost: request.useSpeakerBoost,
          ),
        ),
      ),
    );

    final metadata = result.providerMetadata?.namespace('elevenlabs');

    return TTSResponse(
      audioData: result.audioBytes,
      contentType: result.mediaType,
      voice: request.voice,
      model: request.model,
      duration: null,
      sampleRate: null,
      usage: null,
      requestId: metadata?['requestId'] as String?,
    );
  }

  Future<STTResponse> _bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final model = _modernProvider.transcriptionModel(
      request.model ?? config.defaultSTTModel,
    );

    final result = await model.transcribe(
      core.TranscriptionRequest(
        audioBytes: request.audioData!,
        mediaType: _legacyAudioMediaType(request.format),
        callOptions: core.CallOptions(
          timeout: config.timeout,
          cancellation: cancelToken,
          providerOptions: modern_community.ElevenLabsTranscriptionOptions(
            languageCode: request.language,
            tagAudioEvents: request.tagAudioEvents,
            numSpeakers: request.numSpeakers,
            timestampGranularity:
                _toModernTimestampGranularity(request.timestampGranularity),
            diarize: request.diarize,
            fileFormat: _toModernTranscriptionFileFormat(request.format),
            enableLogging: request.enableLogging,
          ),
        ),
      ),
    );

    final metadata = result.providerMetadata?.namespace('elevenlabs');
    final languageProbability = _asDouble(metadata?['languageProbability']);

    return STTResponse(
      text: result.text,
      language: metadata?['languageCode'] as String?,
      confidence: languageProbability,
      words: _decodeLegacyWordTimings(metadata?['words']),
      model: request.model,
      duration: null,
      usage: null,
      languageProbability: languageProbability,
      additionalFormats: _asStringDynamicMap(metadata?['additionalFormats']),
    );
  }
}

bool _canUseElevenLabsSpeechBridge(TTSRequest request) {
  return _isValidSpeechRatio(request.stability) &&
      _isValidSpeechRatio(request.similarityBoost) &&
      _isValidSpeechRatio(request.style) &&
      _isValidSpeechSeed(request.seed);
}

bool _canUseElevenLabsTranscriptionBridge(STTRequest request) {
  if (request.audioData == null) {
    return false;
  }

  if (request.timestampGranularity == TimestampGranularity.segment) {
    return false;
  }

  final numSpeakers = request.numSpeakers;
  if (numSpeakers != null && (numSpeakers < 1 || numSpeakers > 32)) {
    return false;
  }

  return true;
}

bool _isValidSpeechRatio(double? value) {
  return value == null || (value >= 0 && value <= 1);
}

bool _isValidSpeechSeed(int? value) {
  return value == null || (value >= 0 && value <= 4294967295);
}

List<String> _takeAtMostThree(List<String>? values) {
  if (values == null || values.isEmpty) {
    return const [];
  }

  return values.take(3).toList(growable: false);
}

modern_community.ElevenLabsTextNormalization _toModernTextNormalization(
  TextNormalization normalization,
) {
  return switch (normalization) {
    TextNormalization.auto => modern_community.ElevenLabsTextNormalization.auto,
    TextNormalization.on => modern_community.ElevenLabsTextNormalization.on,
    TextNormalization.off => modern_community.ElevenLabsTextNormalization.off,
  };
}

modern_community.ElevenLabsTranscriptionTimestampGranularity?
    _toModernTimestampGranularity(
  TimestampGranularity granularity,
) {
  return switch (granularity) {
    TimestampGranularity.none =>
      modern_community.ElevenLabsTranscriptionTimestampGranularity.none,
    TimestampGranularity.word =>
      modern_community.ElevenLabsTranscriptionTimestampGranularity.word,
    TimestampGranularity.character =>
      modern_community.ElevenLabsTranscriptionTimestampGranularity.character,
    TimestampGranularity.segment => null,
  };
}

modern_community.ElevenLabsTranscriptionFileFormat?
    _toModernTranscriptionFileFormat(String? format) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return switch (normalized) {
    'pcm_s16le_16' =>
      modern_community.ElevenLabsTranscriptionFileFormat.pcmS16le16,
    _ => modern_community.ElevenLabsTranscriptionFileFormat.other,
  };
}

String? _mapLegacySpeechOutputFormat(
  String? format, {
  required int? sampleRate,
}) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return switch (normalized) {
    'mp3' || 'mp3_128' => 'mp3',
    'mp3_32' => 'mp3_32',
    'mp3_64' => 'mp3_64',
    'mp3_96' => 'mp3_96',
    'mp3_192' || 'mp3_44100_192' => 'mp3_44100_192',
    'mp3_44100_32' => 'mp3_44100_32',
    'mp3_44100_64' => 'mp3_44100_64',
    'mp3_44100_96' => 'mp3_44100_96',
    'mp3_44100_128' => 'mp3_44100_128',
    'pcm' || 'wav' => _mapLegacyPcmOutputFormat(sampleRate),
    'ulaw' || 'ulaw_8000' => 'ulaw_8000',
    'pcm_16000' || 'pcm_22050' || 'pcm_24000' || 'pcm_44100' => normalized,
    _ => format,
  };
}

String _mapLegacyPcmOutputFormat(int? sampleRate) {
  return switch (sampleRate) {
    16000 => 'pcm_16000',
    22050 => 'pcm_22050',
    24000 => 'pcm_24000',
    _ => 'pcm_44100',
  };
}

String _legacyAudioMediaType(String? format) {
  final normalized = format?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return 'audio/wav';
  }

  if (normalized.contains('/')) {
    return normalized;
  }

  return switch (normalized) {
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'webm' => 'audio/webm',
    'mp4' => 'audio/mp4',
    'm4a' => 'audio/m4a',
    'ogg' => 'audio/ogg',
    'flac' => 'audio/flac',
    'pcm' || 'pcm_s16le_16' => 'audio/pcm',
    _ => 'audio/$normalized',
  };
}

double? _asDouble(Object? value) {
  return switch (value) {
    num() => value.toDouble(),
    _ => null,
  };
}

Map<String, dynamic>? _asStringDynamicMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  return value.map(
    (key, nestedValue) => MapEntry(key as String, nestedValue),
  );
}

List<WordTiming>? _decodeLegacyWordTimings(Object? value) {
  if (value is! List) {
    return null;
  }

  final words = <WordTiming>[];
  for (final item in value) {
    if (item is! Map) {
      continue;
    }

    final text = item['text'];
    final start = item['start'];
    final end = item['end'];
    if (text is! String || start is! num || end is! num) {
      continue;
    }

    words.add(
      WordTiming(
        word: text,
        start: start.toDouble(),
        end: end.toDouble(),
        confidence: _asDouble(item['confidence']),
      ),
    );
  }

  return words.isEmpty ? null : words;
}
