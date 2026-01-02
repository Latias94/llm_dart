import 'package:llm_dart_core/llm_dart_core.dart';

import 'audio.dart';
import 'client.dart';
import 'config.dart';
import 'models.dart';

/// ElevenLabs Provider implementation.
class ElevenLabsProvider
    implements
        TextToSpeechCapability,
        StreamingTextToSpeechCapability,
        VoiceListingCapability,
        SpeechToTextCapability,
        TranscriptionLanguageListingCapability {
  final ElevenLabsConfig config;
  final ElevenLabsClient _client;
  late final ElevenLabsAudio audio;
  late final ElevenLabsModels models;

  ElevenLabsProvider(this.config) : _client = ElevenLabsClient(config) {
    audio = ElevenLabsAudio(_client, config);
    models = ElevenLabsModels(_client, config);
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
