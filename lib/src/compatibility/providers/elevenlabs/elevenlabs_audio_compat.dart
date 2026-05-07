import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/client.dart';
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_audio_support.dart';

part 'elevenlabs_audio_endpoint_support.dart';

/// Compatibility-oriented ElevenLabs audio capability implementation.
class ElevenLabsAudio extends BaseAudioCapability {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;
  final _ElevenLabsAudioEndpointSupport _endpoints;

  ElevenLabsAudio(this.client, this.config)
      : _endpoints = _ElevenLabsAudioEndpointSupport(
          client: client,
          config: config,
        );

  @override
  Set<AudioFeature> get supportedFeatures => {
        AudioFeature.textToSpeech,
        AudioFeature.speechToText,
        AudioFeature.streamingTTS,
        AudioFeature.speakerDiarization,
        AudioFeature.characterTiming,
        AudioFeature.audioEventDetection,
        if (config.supportsRealTimeStreaming) AudioFeature.realtimeProcessing,
      };

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _endpoints.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return _endpoints.getVoices();
  }

  @override
  List<String> getSupportedAudioFormats() {
    return config.supportedAudioFormats;
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _endpoints.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return ElevenLabsAudioSupport.supportedLanguages;
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError('Streaming TTS implementation pending');
  }

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError('ElevenLabs does not support audio translation');
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) {
    throw UnsupportedError('Real-time audio session implementation pending');
  }
}
