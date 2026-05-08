part of 'shell_support.dart';

final class _ElevenLabsCompatBridgeRouter {
  final ElevenLabsAudio audio;
  final ElevenLabsAudioBridgeSupport bridgeSupport;

  const _ElevenLabsCompatBridgeRouter({
    required this.audio,
    required this.bridgeSupport,
  });

  bool canUseSpeechBridge(TTSRequest request) {
    return bridgeSupport.canUseSpeechBridge(request);
  }

  bool canUseTranscriptionBridge(STTRequest request) {
    return bridgeSupport.canUseTranscriptionBridge(request);
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return bridgeSupport.bridgeTextToSpeech(
      request,
      cancelToken: cancelToken,
    );
  }

  Future<TTSResponse> textToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatBridge(
      canUseBridge: canUseSpeechBridge(request),
      bridge: () => bridgeTextToSpeech(
        request,
        cancelToken: cancelToken,
      ),
      fallback: () => audio.textToSpeech(
        request,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return bridgeSupport.bridgeSpeechToText(
      request,
      cancelToken: cancelToken,
    );
  }

  Future<STTResponse> speechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return executeCompatBridge(
      canUseBridge: canUseTranscriptionBridge(request),
      bridge: () => bridgeSpeechToText(
        request,
        cancelToken: cancelToken,
      ),
      fallback: () => audio.speechToText(
        request,
        cancelToken: cancelToken,
      ),
    );
  }
}
