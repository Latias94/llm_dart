part of 'provider_compat.dart';

final class _ElevenLabsProviderAudioShortcuts {
  final ElevenLabsCompatShellSupport _shell;

  const _ElevenLabsProviderAudioShortcuts(this._shell);

  Future<List<int>> speech(
    String text, {
    TransportCancellation? cancelToken,
  }) async {
    final response = await _shell.textToSpeech(
      TTSRequest(text: text),
      cancelToken: cancelToken,
    );
    return response.audioData;
  }

  Stream<List<int>> speechStream(String text) async* {
    await for (final event
        in _shell.textToSpeechStream(TTSRequest(text: text))) {
      if (event is AudioDataEvent) {
        yield event.data;
      }
    }
  }

  Future<String> transcribe(List<int> audio) async {
    final response = await _shell.speechToText(STTRequest.fromAudio(audio));
    return response.text;
  }

  Future<String> transcribeFile(String filePath) async {
    final response = await _shell.speechToText(STTRequest.fromFile(filePath));
    return response.text;
  }
}
