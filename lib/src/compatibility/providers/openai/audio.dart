import '../../../../core/capability.dart';
import '../../../../models/audio_models.dart';
import 'client.dart';
import 'openai_audio_catalog.dart';
import 'openai_audio_support.dart';
import '../../../../providers/openai/config.dart';

/// OpenAI Audio capabilities implementation
///
/// This module handles text-to-speech, speech-to-text, and audio translation
/// functionality for OpenAI providers.
class OpenAIAudio extends BaseAudioCapability {
  final OpenAIClient client;
  final OpenAIConfig config;
  late final OpenAIAudioSupport _audioSupport;

  OpenAIAudio(this.client, this.config) {
    _audioSupport = OpenAIAudioSupport(config);
  }

  // AudioCapability implementation

  @override
  Set<AudioFeature> get supportedFeatures => {
        AudioFeature.textToSpeech,
        AudioFeature.speechToText,
        AudioFeature.audioTranslation,
        // OpenAI doesn't support streaming TTS or real-time processing
      };

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final speechRequest = _audioSupport.buildSpeechRequest(request);

    final audioData = await client.postRaw(
      'audio/speech',
      speechRequest.body,
      cancelToken: cancelToken,
    );

    return _audioSupport.buildSpeechResponse(
      request: request,
      audioData: audioData,
      voice: speechRequest.voice,
      contentType: speechRequest.contentType,
    );
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return OpenAIAudioCatalog.voices;
  }

  @override
  List<String> getSupportedAudioFormats() {
    return OpenAIAudioCatalog.supportedTtsFormats();
  }

  // SpeechToTextCapability implementation

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final formData = await _audioSupport.buildTranscriptionFormData(request);

    final responseData = await client.postForm(
      'audio/transcriptions',
      formData,
      cancelToken: cancelToken,
    );

    return _audioSupport.buildTranscriptionResponse(request, responseData);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return OpenAIAudioCatalog.supportedLanguages;
  }

  // Audio translation implementation (OpenAI specific)

  @override
  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    final formData = await _audioSupport.buildTranslationFormData(request);

    final responseData = await client.postForm(
      'audio/translations',
      formData,
      cancelToken: cancelToken,
    );

    return _audioSupport.buildTranslationResponse(request, responseData);
  }

  // Unsupported features - throw UnsupportedError

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    throw UnsupportedError('OpenAI does not support streaming text-to-speech');
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
      RealtimeAudioConfig config) {
    throw UnsupportedError('OpenAI does not support real-time audio sessions');
  }
}
