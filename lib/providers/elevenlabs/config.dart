import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, HasDioClientOverrides;

import 'defaults.dart';

/// ElevenLabs provider configuration
///
/// This class contains all configuration options for the ElevenLabs providers.
/// ElevenLabs specializes in text-to-speech and speech-to-text capabilities.
class ElevenLabsConfig implements HasDioClientOverrides {
  final String apiKey;
  final String baseUrl;
  final String? voiceId;
  final String? model;
  final Duration? timeout;
  @override
  final DioClientOverrides? dioOverrides;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  const ElevenLabsConfig({
    required this.apiKey,
    this.baseUrl = ElevenLabsDefaults.baseUrl,
    this.voiceId,
    this.model,
    this.timeout,
    this.dioOverrides,
    this.stability,
    this.similarityBoost,
    this.style,
    this.useSpeakerBoost,
  });

  /// Check if this configuration supports text-to-speech
  bool get supportsTextToSpeech => true;

  /// Check if this configuration supports speech-to-text
  bool get supportsSpeechToText => true;

  /// Check if this configuration supports voice cloning
  bool get supportsVoiceCloning => true;

  /// Check if this configuration supports real-time streaming
  bool get supportsRealTimeStreaming => true;

  /// Get the default voice ID
  String get defaultVoiceId => voiceId ?? ElevenLabsDefaults.defaultVoiceId;

  /// Get the default TTS model (matches ElevenLabs API documentation)
  String get defaultTTSModel => model ?? ElevenLabsDefaults.defaultTtsModel;

  /// Get the default STT model (matches ElevenLabs API documentation)
  String get defaultSTTModel => ElevenLabsDefaults.defaultSttModel;

  /// Get supported audio formats
  List<String> get supportedAudioFormats =>
      ElevenLabsDefaults.supportedAudioFormats;

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
    DioClientOverrides? dioOverrides,
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
        dioOverrides: dioOverrides ?? this.dioOverrides,
        stability: stability ?? this.stability,
        similarityBoost: similarityBoost ?? this.similarityBoost,
        style: style ?? this.style,
        useSpeakerBoost: useSpeakerBoost ?? this.useSpeakerBoost,
      );
}
