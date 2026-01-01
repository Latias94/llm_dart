import 'package:llm_dart_core/llm_dart_core.dart';

import 'audio.dart';
import 'client.dart';
import 'config.dart';
import 'forced_alignment.dart';
import 'models.dart';
import 'speech_to_speech.dart';

/// ElevenLabs Provider implementation.
class ElevenLabsProvider
    implements
        TextToSpeechCapability,
        StreamingTextToSpeechCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        TranscriptionLanguageListingCapability {
  final ElevenLabsConfig config;
  final ElevenLabsClient client;
  late final ElevenLabsAudio audio;
  late final ElevenLabsModels models;
  late final ElevenLabsSpeechToSpeech speechToSpeech;
  late final ElevenLabsForcedAlignment forcedAlignment;

  ElevenLabsProvider(this.config) : client = ElevenLabsClient(config) {
    audio = ElevenLabsAudio(client, config);
    models = ElevenLabsModels(client, config);
    speechToSpeech = ElevenLabsSpeechToSpeech(client, config);
    forcedAlignment = ElevenLabsForcedAlignment(client, config);
  }

  String get providerName => 'ElevenLabs';

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    CancelToken? cancelToken,
  }) async {
    return audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    CancelToken? cancelToken,
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
    CancelToken? cancelToken,
  }) async {
    return audio.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return audio.getSupportedLanguages();
  }

  List<String> getSupportedAudioFormats() {
    return audio.getSupportedAudioFormats();
  }

  Future<List<Map<String, dynamic>>> getModels() async {
    return models.getModels();
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    return models.getUserInfo();
  }

  /// ElevenLabs speech-to-speech (voice conversion).
  ///
  /// Official API: `POST /v1/speech-to-speech/{voice_id}`
  Future<SpeechToSpeechResponse> convertSpeechToSpeech(
    SpeechToSpeechRequest request, {
    CancelToken? cancelToken,
  }) {
    return speechToSpeech.convert(request, cancelToken: cancelToken);
  }

  /// ElevenLabs speech-to-speech streaming.
  ///
  /// Official API: `POST /v1/speech-to-speech/{voice_id}/stream`
  Stream<AudioStreamEvent> convertSpeechToSpeechStream(
    SpeechToSpeechRequest request, {
    CancelToken? cancelToken,
  }) {
    return speechToSpeech.convertStream(request, cancelToken: cancelToken);
  }

  /// Create forced alignment for an audio file + transcript.
  ///
  /// Official API: `POST /v1/forced-alignment`
  Future<ForcedAlignmentResponse> createForcedAlignment(
    ForcedAlignmentRequest request, {
    CancelToken? cancelToken,
  }) {
    return forcedAlignment.create(request, cancelToken: cancelToken);
  }

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

  Map<String, dynamic> get info => {
        'provider': providerName,
        'baseUrl': config.baseUrl,
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
}
