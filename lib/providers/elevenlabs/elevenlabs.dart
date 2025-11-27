/// Modular ElevenLabs Provider
///
/// This library provides a modular implementation of the ElevenLabs provider
/// following the same architecture pattern as other providers.
///
/// **Key Features:**
/// - High-quality text-to-speech synthesis
/// - Speech-to-text transcription
/// - Voice cloning and customization
/// - Multiple language support
/// - Real-time streaming capabilities
/// - Modular architecture for easy maintenance
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
import 'provider.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'audio.dart';
export 'models.dart';

/// Create an ElevenLabs provider with default settings
ElevenLabsProvider createElevenLabsProvider({
  required String apiKey,
  String baseUrl = 'https://api.elevenlabs.io/v1/',
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

/// Create an ElevenLabs provider optimized for high-quality TTS
ElevenLabsProvider createElevenLabsTTSProvider({
  required String apiKey,
  String voiceId = 'JBFqnCBsd6RMkjVDRZzb',
  String model = 'eleven_multilingual_v2',
  double stability = 0.5,
  double similarityBoost = 0.75,
  double style = 0.0,
  bool useSpeakerBoost = true,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    voiceId: voiceId,
    model: model,
    stability: stability,
    similarityBoost: similarityBoost,
    style: style,
    useSpeakerBoost: useSpeakerBoost,
  );

  return ElevenLabsProvider(config);
}

/// Create an ElevenLabs provider optimized for STT
ElevenLabsProvider createElevenLabsSTTProvider({
  required String apiKey,
  String model = 'scribe_v1',
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    model: model,
  );

  return ElevenLabsProvider(config);
}

/// Create an ElevenLabs provider with custom voice settings
ElevenLabsProvider createElevenLabsCustomVoiceProvider({
  required String apiKey,
  required String voiceId,
  String model = 'eleven_multilingual_v2',
  double stability = 0.5,
  double similarityBoost = 0.75,
  double style = 0.0,
  bool useSpeakerBoost = true,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    voiceId: voiceId,
    model: model,
    stability: stability,
    similarityBoost: similarityBoost,
    style: style,
    useSpeakerBoost: useSpeakerBoost,
  );

  return ElevenLabsProvider(config);
}

/// Create an ElevenLabs provider for real-time streaming
ElevenLabsProvider createElevenLabsStreamingProvider({
  required String apiKey,
  String voiceId = 'JBFqnCBsd6RMkjVDRZzb',
  String model = 'eleven_turbo_v2', // Faster model for streaming
  double stability = 0.5,
  double similarityBoost = 0.75,
}) {
  final config = ElevenLabsConfig(
    apiKey: apiKey,
    voiceId: voiceId,
    model: model,
    stability: stability,
    similarityBoost: similarityBoost,
    timeout: const Duration(seconds: 30), // Shorter timeout for streaming
  );

  return ElevenLabsProvider(config);
}
