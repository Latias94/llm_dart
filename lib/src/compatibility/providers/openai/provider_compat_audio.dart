part of 'provider_compat.dart';

mixin OpenAIProviderAudioMixin implements AudioCapability {
  OpenAIAudio get _audio;
  OpenAIProviderSupport get _support;

  @override
  Set<AudioFeature> get supportedFeatures => _audio.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _audio.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _audio.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return _audio.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _audio.speechToText(request, cancelToken: cancelToken);
  }

  Future<STTResponse> translateAudio(
    AudioTranslationRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _audio.translateAudio(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return _audio.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) async {
    return _audio.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return _audio.getSupportedAudioFormats();
  }

  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    return _support.speech(
      text,
      cancelToken: cancelToken,
    );
  }

  @override
  Stream<List<int>> speechStream(String text) {
    return _support.speechStream(text);
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    return _support.transcribe(audio);
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    return _support.transcribeFile(filePath);
  }

  Future<String> translate(List<int> audio) async {
    return _support.translate(audio);
  }

  Future<String> translateFile(String filePath) async {
    return _support.translateFile(filePath);
  }
}
