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
  }) async {
    if (canUseSpeechBridge(request)) {
      try {
        return await bridgeTextToSpeech(
          request,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return audio.textToSpeech(request, cancelToken: cancelToken);
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
  }) async {
    if (canUseTranscriptionBridge(request)) {
      try {
        return await bridgeSpeechToText(
          request,
          cancelToken: cancelToken,
        );
      } catch (error) {
        if (!isCompatibilityError(error)) {
          rethrow;
        }
      }
    }

    return audio.speechToText(request, cancelToken: cancelToken);
  }
}
