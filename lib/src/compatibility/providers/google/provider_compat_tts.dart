part of 'provider_compat.dart';

mixin _GoogleProviderTTS implements GoogleTTSCapability {
  GoogleTTS get _tts;

  @override
  Future<GoogleTTSResponse> generateSpeech(GoogleTTSRequest request) async {
    return _tts.generateSpeech(request);
  }

  @override
  Stream<GoogleTTSStreamEvent> generateSpeechStream(GoogleTTSRequest request) {
    return _tts.generateSpeechStream(request);
  }

  @override
  Future<List<GoogleVoiceInfo>> getAvailableVoices() async {
    return _tts.getAvailableVoices();
  }

  @override
  Future<List<String>> getSupportedLanguages() async {
    return _tts.getSupportedLanguages();
  }
}
