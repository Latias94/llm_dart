part of 'provider_compat.dart';

mixin _ElevenLabsProviderAudio implements AudioCapability {
  ElevenLabsCompatShellSupport get _compatShell;
  _ElevenLabsProviderAudioShortcuts get _audioShortcuts;

  @override
  Set<AudioFeature> get supportedFeatures => _compatShell.supportedFeatures;

  @override
  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _compatShell.textToSpeech(request, cancelToken: cancelToken);
  }

  @override
  Stream<AudioStreamEvent> textToSpeechStream(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _compatShell.textToSpeechStream(request, cancelToken: cancelToken);
  }

  @override
  Future<List<VoiceInfo>> getVoices() async {
    return _compatShell.getVoices();
  }

  @override
  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) async {
    return _compatShell.speechToText(request, cancelToken: cancelToken);
  }

  @override
  Future<List<LanguageInfo>> getSupportedLanguages() async {
    return _compatShell.getSupportedLanguages();
  }

  @override
  Future<RealtimeAudioSession> startRealtimeSession(
    RealtimeAudioConfig config,
  ) async {
    return _compatShell.startRealtimeSession(config);
  }

  @override
  List<String> getSupportedAudioFormats() {
    return _compatShell.getSupportedAudioFormats();
  }

  @override
  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    return _audioShortcuts.speech(text, cancelToken: cancelToken);
  }

  @override
  Stream<List<int>> speechStream(String text) async* {
    yield* _audioShortcuts.speechStream(text);
  }

  @override
  Future<String> transcribe(List<int> audio) async {
    return _audioShortcuts.transcribe(audio);
  }

  @override
  Future<String> transcribeFile(String filePath) async {
    return _audioShortcuts.transcribeFile(filePath);
  }
}
