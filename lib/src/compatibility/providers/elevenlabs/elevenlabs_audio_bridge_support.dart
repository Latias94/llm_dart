import 'package:llm_dart_community/llm_dart_community.dart' as modern_community;
import 'package:llm_dart_provider/llm_dart_provider.dart' as core;
import 'package:llm_dart_transport/llm_dart_transport.dart'
    show TransportCancellation;

import '../../../../models/audio_models.dart';
import '../../../../providers/elevenlabs/config.dart';

part 'elevenlabs_speech_bridge_support.dart';
part 'elevenlabs_transcription_bridge_support.dart';

/// Bridge-local request shaping and response normalization for ElevenLabs.
///
/// This keeps modern-community bridge constraints and codec translation out of
/// the compatibility shell so the shell can stay focused on bridge-vs-fallback
/// orchestration.
final class ElevenLabsAudioBridgeSupport
    with _ElevenLabsSpeechBridgeSupport, _ElevenLabsTranscriptionBridgeSupport {
  @override
  final ElevenLabsConfig config;
  @override
  final modern_community.ElevenLabs modernProvider;

  const ElevenLabsAudioBridgeSupport({
    required this.config,
    required this.modernProvider,
  });
}
