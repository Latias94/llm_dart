import 'package:llm_dart_core/llm_dart_core.dart';

import '../config/elevenlabs_config.dart';
import '../provider/elevenlabs_provider.dart';

const _defaultBaseUrl = 'https://api.elevenlabs.io/v1/';

/// ElevenLabs provider settings (Vercel AI-style).
///
/// Mirrors the core fields from `ElevenLabsProviderSettings` in the Vercel AI SDK
/// while using Dart naming conventions:
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
/// Provides a model-centric API similar to `createElevenLabs` in the Vercel AI SDK.
/// It returns [AudioCapability] instances via the [SpeechModelProviderFactory]
/// interface, which can be used with helpers like [generateSpeech] or
/// [transcribe].
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
    return ElevenLabsProvider(config);
  }

  /// Create a speech (text-to-speech) model.
  @override
  AudioCapability speech(String modelId) {
    final config = _createConfig(modelId);
    return ElevenLabsProvider(config);
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
