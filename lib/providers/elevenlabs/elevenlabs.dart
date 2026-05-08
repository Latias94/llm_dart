/// Compatibility-first root ElevenLabs provider entrypoint.
///
/// For new shared-capability code, prefer the package-owned modern ElevenLabs
/// surfaces in `package:llm_dart_community/llm_dart_community.dart`:
///
/// - `ElevenLabs(...).speechModel(...)`
/// - `ElevenLabs(...).transcriptionModel(...)`
///
/// Keep this root entrypoint only when you still need the legacy root provider
/// surface, compatibility audio capability interfaces, or residual
/// provider-shaped APIs such as voice catalogs, realtime audio, and account
/// helpers.
///
/// **Usage:**
/// ```dart
/// import 'package:llm_dart/providers/elevenlabs/elevenlabs.dart';
///
/// final provider = ElevenLabsProvider(ElevenLabsConfig(
///   apiKey: 'your-api-key',
///   voiceId: 'JBFqnCBsd6RMkjVDRZzb',
/// ));
///
/// // Text-to-speech
/// final ttsResponse = await provider.textToSpeech(TTSRequest(
///   text: 'Hello, world!',
///   voice: 'JBFqnCBsd6RMkjVDRZzb',
/// ));
///
/// // Speech-to-text
/// final sttResponse = await provider.speechToText(STTRequest.fromFile(
///   'path/to/audio.wav',
/// ));
///
/// // Get available voices
/// final voices = await provider.getVoices();
/// for (final voice in voices) {
///   print('${voice.name}: ${voice.id}');
/// }
/// ```
library;

import 'config.dart';
import 'defaults.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'defaults.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'audio.dart';
export 'models.dart';

/// Create an ElevenLabs provider with default settings
ElevenLabsProvider createElevenLabsProvider({
  required String apiKey,
  String baseUrl = ElevenLabsDefaults.baseUrl,
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
