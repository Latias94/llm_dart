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

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'audio.dart';
export 'models.dart';

// Vercel AI-style facade exports (model-centric API).
export 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    show
        ElevenLabsProviderSettings,
        ElevenLabs,
        createElevenLabs,
        elevenlabs;
