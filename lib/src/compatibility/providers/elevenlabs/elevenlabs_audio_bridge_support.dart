import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    as modern_elevenlabs;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show TransportCancellation;

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';

part 'elevenlabs_speech_bridge_support.dart';
part 'elevenlabs_transcription_bridge_support.dart';

/// Bridge-local request shaping and response normalization for ElevenLabs.
///
/// This keeps dedicated-package bridge constraints and codec translation out of
/// the compatibility shell so the shell can stay focused on bridge-vs-fallback
/// orchestration.
final class ElevenLabsAudioBridgeSupport {
  final ElevenLabsConfig config;
  final modern_elevenlabs.ElevenLabs modernProvider;
  final _ElevenLabsSpeechBridgeSupport _speechSupport;
  final _ElevenLabsTranscriptionBridgeSupport _transcriptionSupport;

  ElevenLabsAudioBridgeSupport({
    required this.config,
    required this.modernProvider,
  })  : _speechSupport = _ElevenLabsSpeechBridgeSupport(
          config: config,
          modernProvider: modernProvider,
        ),
        _transcriptionSupport = _ElevenLabsTranscriptionBridgeSupport(
          config: config,
          modernProvider: modernProvider,
        );

  bool canUseSpeechBridge(TTSRequest request) {
    return _speechSupport.canUseSpeechBridge(request);
  }

  Future<TTSResponse> bridgeTextToSpeech(
    TTSRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _speechSupport.bridgeTextToSpeech(
      request,
      cancelToken: cancelToken,
    );
  }

  bool canUseTranscriptionBridge(STTRequest request) {
    return _transcriptionSupport.canUseTranscriptionBridge(request);
  }

  Future<STTResponse> bridgeSpeechToText(
    STTRequest request, {
    TransportCancellation? cancelToken,
  }) {
    return _transcriptionSupport.bridgeSpeechToText(
      request,
      cancelToken: cancelToken,
    );
  }
}

modern_elevenlabs.ElevenLabsSpeechOptions? _resolveElevenLabsSpeechOptions(
  Object? options,
) {
  if (options == null) {
    return null;
  }
  if (options is modern_elevenlabs.ElevenLabsSpeechOptions) {
    return options;
  }
  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected ElevenLabsSpeechOptions for ElevenLabs speech requests.',
  );
}

modern_elevenlabs.ElevenLabsTranscriptionOptions?
    _resolveElevenLabsTranscriptionOptions(Object? options) {
  if (options == null) {
    return null;
  }
  if (options is modern_elevenlabs.ElevenLabsTranscriptionOptions) {
    return options;
  }
  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected ElevenLabsTranscriptionOptions for ElevenLabs transcription requests.',
  );
}
