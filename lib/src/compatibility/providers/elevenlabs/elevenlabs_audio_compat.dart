import '../../../../core/capability.dart';
import '../../../../core/llm_error.dart';
import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/client.dart';
import '../../../../providers/elevenlabs/config.dart';
import 'elevenlabs_audio_support.dart';

/// Compatibility-oriented ElevenLabs audio capability implementation.
class ElevenLabsAudio extends BaseAudioCapability {
  final ElevenLabsClient client;
  final ElevenLabsConfig config;
  final ElevenLabsAudioSupport _support = const ElevenLabsAudioSupport();

  ElevenLabsAudio(this.client, this.config);

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
    _ensureApiKey();
    final effectiveVoiceId = request.voice ?? config.defaultVoiceId;
    final effectiveModel = request.model ?? config.defaultTTSModel;

    client.logger.info(
      'Converting text to speech with voice: $effectiveVoiceId, model: $effectiveModel',
    );

    try {
      final audioData = await client.postBinary(
        'text-to-speech/$effectiveVoiceId',
        _support.buildTextToSpeechRequestBody(
          request,
          config: config,
          effectiveModel: effectiveModel,
        ),
        queryParams: _support.buildTextToSpeechQueryParams(request),
        cancelToken: cancelToken,
      );

      return _support.buildTextToSpeechResponse(
        audioData,
        request: request,
        contentType: 'audio/mpeg',
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during text-to-speech: $e');
    }
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    final rawVoices = await _getVoicesRaw();
    return _support.mapVoices(rawVoices);
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
    if (request.audioData != null) {
      return _speechToTextFromBytes(
        request,
        cancelToken: cancelToken,
      );
    } else if (request.filePath != null) {
      return _speechToTextFromFile(
        request,
        cancelToken: cancelToken,
      );
    } else {
      throw const InvalidRequestError(
          'Either audioData or filePath must be provided');
    }
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return ElevenLabsAudioSupport.supportedLanguages;
  }

  Future<STTResponse> _speechToTextFromBytes(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    _ensureApiKey();
    final effectiveModel = request.model ?? config.defaultSTTModel;

    client.logger.info('Converting speech to text with model: $effectiveModel');

    try {
      final formData = await _support.buildSpeechToTextFormDataFromBytes(
        request.audioData!,
        request: request,
        effectiveModel: effectiveModel,
      );

      final responseData = await client.postFormData(
        'speech-to-text',
        formData,
        queryParams: _support.buildSpeechToTextQueryParams(request),
        cancelToken: cancelToken,
      );

      return _parseSpeechToTextResponse(responseData, request);
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError('Unexpected error during speech-to-text: $e');
    }
  }

  Future<STTResponse> _speechToTextFromFile(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    _ensureApiKey();
    final effectiveModel = request.model ?? config.defaultSTTModel;

    client.logger.info(
      'Converting speech file to text: ${request.filePath}, model: $effectiveModel',
    );

    try {
      final formData = await _support.buildSpeechToTextFormDataFromFile(
        request.filePath!,
        request: request,
        effectiveModel: effectiveModel,
      );

      final responseData = await client.postFormData(
        'speech-to-text',
        formData,
        cancelToken: cancelToken,
      );

      return _parseSpeechToTextResponse(responseData, request);
    } catch (e) {
      if (e is LLMError) rethrow;
      throw GenericError(
          'Unexpected error during speech-to-text from file: $e');
    }
  }

  STTResponse _parseSpeechToTextResponse(
    Map<String, dynamic> responseData,
    STTRequest request,
  ) {
    try {
      return _support.parseSpeechToTextResponse(
        responseData,
        request: request,
      );
    } catch (e) {
      throw ResponseFormatError(
        'Failed to parse ElevenLabs STT response: $e',
        responseData.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _getVoicesRaw() async {
    final responseData = await client.getJson('voices');
    final voices = responseData['voices'] as List<dynamic>? ?? [];
    return voices.cast<Map<String, dynamic>>();
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

  void _ensureApiKey() {
    if (config.apiKey.isEmpty) {
      throw const AuthError('Missing ElevenLabs API key');
    }
  }
}
