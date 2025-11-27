import 'package:llm_dart_core/llm_dart_core.dart';

const String _defaultBaseUrl = 'https://api.elevenlabs.io/v1/';
const String _defaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';
const String _defaultTTSModel = 'eleven_multilingual_v2';
const String _defaultSTTModel = 'scribe_v1';

const List<String> _supportedAudioFormats = [
  'mp3_44100_128',
  'mp3_44100_192',
  'pcm_16000',
  'pcm_22050',
  'pcm_24000',
  'pcm_44100',
  'ulaw_8000',
];

/// ElevenLabs provider configuration
///
/// This class contains all configuration options for the ElevenLabs providers.
/// ElevenLabs specializes in text-to-speech and speech-to-text capabilities.
class ElevenLabsConfig {
  final String apiKey;
  final String baseUrl;
  final String? voiceId;
  final String? model;
  final Duration? timeout;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  /// Reference to original LLMConfig for accessing extensions
  final LLMConfig? _originalConfig;

  const ElevenLabsConfig({
    required this.apiKey,
    this.baseUrl = _defaultBaseUrl,
    this.voiceId,
    this.model,
    this.timeout,
    this.stability,
    this.similarityBoost,
    this.style,
    this.useSpeakerBoost,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create ElevenLabsConfig from unified LLMConfig
  factory ElevenLabsConfig.fromLLMConfig(LLMConfig config) {
    return ElevenLabsConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl.isNotEmpty ? config.baseUrl : _defaultBaseUrl,
      model: config.model,
      timeout: config.timeout,
      // ElevenLabs-specific extensions
      voiceId: config.getExtension<String>('voiceId'),
      stability: config.getExtension<double>('stability'),
      similarityBoost: config.getExtension<double>('similarityBoost'),
      style: config.getExtension<double>('style'),
      useSpeakerBoost: config.getExtension<bool>('useSpeakerBoost'),
      originalConfig: config,
    );
  }

  /// Get extension value from original config
  T? getExtension<T>(String key) => _originalConfig?.getExtension<T>(key);

  /// Get the original LLMConfig for HTTP configuration
  LLMConfig? get originalConfig => _originalConfig;

  /// Check if this configuration supports text-to-speech
  bool get supportsTextToSpeech => true;

  /// Check if this configuration supports speech-to-text
  bool get supportsSpeechToText => true;

  /// Check if this configuration supports voice cloning
  bool get supportsVoiceCloning => true;

  /// Check if this configuration supports real-time streaming
  bool get supportsRealTimeStreaming => true;

  /// Get the default voice ID
  String get defaultVoiceId => voiceId ?? _defaultVoiceId;

  /// Get the default TTS model (matches ElevenLabs API documentation)
  String get defaultTTSModel => model ?? _defaultTTSModel;

  /// Get the default STT model (matches ElevenLabs API documentation)
  String get defaultSTTModel => _defaultSTTModel;

  /// Get supported audio formats
  List<String> get supportedAudioFormats => _supportedAudioFormats;

  /// Get voice settings for TTS
  Map<String, dynamic> get voiceSettings => {
        if (stability != null) 'stability': stability,
        if (similarityBoost != null) 'similarity_boost': similarityBoost,
        if (style != null) 'style': style,
        if (useSpeakerBoost != null) 'use_speaker_boost': useSpeakerBoost,
      };

  ElevenLabsConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? voiceId,
    String? model,
    Duration? timeout,
    double? stability,
    double? similarityBoost,
    double? style,
    bool? useSpeakerBoost,
  }) =>
      ElevenLabsConfig(
        apiKey: apiKey ?? this.apiKey,
        baseUrl: baseUrl ?? this.baseUrl,
        voiceId: voiceId ?? this.voiceId,
        model: model ?? this.model,
        timeout: timeout ?? this.timeout,
        stability: stability ?? this.stability,
        similarityBoost: similarityBoost ?? this.similarityBoost,
        style: style ?? this.style,
        useSpeakerBoost: useSpeakerBoost ?? this.useSpeakerBoost,
      );
}
