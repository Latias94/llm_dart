/// Modular ElevenLabs Provider
///
/// ElevenLabs specializes in text-to-speech and speech-to-text services.
library;

import 'defaults.dart';

import 'config.dart';
import 'provider.dart';

export 'audio.dart';
export 'config.dart';
export 'models.dart';
export 'provider.dart';
//
// Advanced endpoint wrappers are opt-in:
// - `package:llm_dart_elevenlabs/forced_alignment.dart`
// - `package:llm_dart_elevenlabs/speech_to_speech.dart`

ElevenLabsProvider createElevenLabsProvider({
  required String apiKey,
  String baseUrl = elevenLabsBaseUrl,
  String? voiceId,
  String? model,
  Duration? timeout,
  double? stability,
  double? similarityBoost,
  double? style,
  bool? useSpeakerBoost,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    baseUrl: baseUrl,
    voiceId: voiceId,
    model: model,
    timeout: timeout,
    stability: stability,
    similarityBoost: similarityBoost,
    style: style,
    useSpeakerBoost: useSpeakerBoost,
  );

  return ElevenLabsProvider(config);
}
