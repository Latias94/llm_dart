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

import 'package:llm_dart_core/llm_dart_core.dart';
import 'config.dart';
import 'provider.dart';

// Core exports
export 'config.dart';
export 'client.dart';
export 'provider.dart';

// Capability modules
export 'audio.dart';
export 'models.dart';

const _defaultBaseUrl = 'https://api.elevenlabs.io/v1/';

/// ElevenLabs provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `ElevenLabsProviderSettings` in the
/// Vercel AI SDK while using Dart naming conventions:
/// - [apiKey] is required.
/// - [baseUrl] and [headers] allow proxying and custom HTTP configuration.
/// - [name] controls the logical provider id used in metadata and registries.
class ElevenLabsProviderSettings {
  /// API key used for authenticating requests.
  final String apiKey;

  /// Base URL for the ElevenLabs API.
  ///
  /// Defaults to `https://api.elevenlabs.io/v1/` when not provided.
  final String? baseUrl;

  /// Additional custom headers to send with each request.
  final Map<String, String>? headers;

  /// Logical provider name used for metadata (e.g. `elevenlabs`).
  final String? name;

  /// Optional default timeout applied via [LLMConfig.timeout].
  final Duration? timeout;

  const ElevenLabsProviderSettings({
    required this.apiKey,
    this.baseUrl,
    this.headers,
    this.name,
    this.timeout,
  });
}

/// ElevenLabs model factory (Vercel AI-style).
///
/// Provides a model-centric API similar to `createElevenLabs` in the
/// Vercel AI SDK. It returns [AudioCapability] instances via the
/// [SpeechModelProviderFactory] interface, which can be used with
/// helpers like [generateSpeech] or [transcribe].
class ElevenLabs implements SpeechModelProviderFactory {
  final ElevenLabsProviderSettings _settings;
  final String _baseUrl;
  final String _providerName;

  ElevenLabs(ElevenLabsProviderSettings settings)
      : _settings = settings,
        _baseUrl = _normalizeBaseUrl(
          settings.baseUrl ?? _defaultBaseUrl,
        ),
        _providerName = settings.name ?? 'elevenlabs';

  /// Create a transcription (speech-to-text) model.
  @override
  AudioCapability transcription(String modelId) {
    final config = _createConfig(modelId);
    final provider = ElevenLabsProvider(config);
    return provider;
  }

  /// Create a speech (text-to-speech) model.
  @override
  AudioCapability speech(String modelId) {
    final config = _createConfig(modelId);
    final provider = ElevenLabsProvider(config);
    return provider;
  }

  ElevenLabsConfig _createConfig(String modelId) {
    final llmConfig = _createLLMConfig(modelId);
    return ElevenLabsConfig.fromLLMConfig(llmConfig);
  }

  LLMConfig _createLLMConfig(String modelId) {
    final headers = <String, String>{};

    if (_settings.headers != null && _settings.headers!.isNotEmpty) {
      headers.addAll(_settings.headers!);
    }

    final extensions = <String, dynamic>{};
    if (headers.isNotEmpty) {
      extensions[LLMConfigKeys.customHeaders] = headers;
    }

    // Attach logical provider name as metadata for observability tooling.
    extensions[LLMConfigKeys.metadata] = <String, dynamic>{
      'provider': _providerName,
    };

    return LLMConfig(
      apiKey: _settings.apiKey,
      baseUrl: _baseUrl,
      model: modelId,
      timeout: _settings.timeout,
      extensions: extensions,
    );
  }

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) return _defaultBaseUrl;
    return value.endsWith('/') ? value : '$value/';
  }
}

/// Create an ElevenLabs model factory (Vercel AI-style).
///
/// Example:
/// ```dart
/// final elevenlabs = createElevenLabs(
///   apiKey: 'eleven-...',
/// );
///
/// final tts = elevenlabs.speech('eleven_multilingual_v2');
/// final result = await generateSpeech(
///   model: 'elevenlabs:eleven_multilingual_v2',
///   text: 'Hello from ElevenLabs!',
/// );
/// ```
ElevenLabs createElevenLabs({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return ElevenLabs(
    ElevenLabsProviderSettings(
      apiKey: apiKey,
      baseUrl: baseUrl,
      headers: headers,
      name: name,
      timeout: timeout,
    ),
  );
}

/// Alias for [createElevenLabs] to mirror a default `elevenlabs` export.
ElevenLabs elevenlabs({
  required String apiKey,
  String? baseUrl,
  Map<String, String>? headers,
  String? name,
  Duration? timeout,
}) {
  return createElevenLabs(
    apiKey: apiKey,
    baseUrl: baseUrl,
    headers: headers,
    name: name,
    timeout: timeout,
  );
}

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
