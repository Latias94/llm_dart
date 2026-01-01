import 'package:llm_dart_core/llm_dart_core.dart';
import 'defaults.dart';

/// ElevenLabs provider configuration.
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

  final LLMConfig? _originalConfig;

  const ElevenLabsConfig({
    required this.apiKey,
    this.baseUrl = elevenLabsBaseUrl,
    this.voiceId,
    this.model,
    this.timeout,
    this.stability,
    this.similarityBoost,
    this.style,
    this.useSpeakerBoost,
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  factory ElevenLabsConfig.fromLLMConfig(LLMConfig config) {
    return ElevenLabsConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      timeout: config.timeout,
      voiceId: config.getProviderOption<String>('elevenlabs', 'voiceId'),
      stability: config.getProviderOption<double>('elevenlabs', 'stability'),
      similarityBoost:
          config.getProviderOption<double>('elevenlabs', 'similarityBoost'),
      style: config.getProviderOption<double>('elevenlabs', 'style'),
      useSpeakerBoost:
          config.getProviderOption<bool>('elevenlabs', 'useSpeakerBoost'),
      originalConfig: config,
    );
  }

  LLMConfig? get originalConfig => _originalConfig;

  bool get supportsTextToSpeech => true;

  bool get supportsSpeechToText => true;

  // ElevenLabs has voice cloning endpoints, but LLM Dart does not currently
  // expose them as a first-class API (best-effort surface is TTS/STT only).
  bool get supportsVoiceCloning => false;

  // ElevenLabs has real-time products/models, but LLM Dart does not currently
  // implement a realtime session transport in this provider.
  bool get supportsRealTimeStreaming => false;

  String get defaultVoiceId => voiceId ?? elevenLabsDefaultVoiceId;

  String get defaultTTSModel => model ?? elevenLabsDefaultTTSModel;

  String get defaultSTTModel => elevenLabsDefaultSTTModel;

  List<String> get supportedAudioFormats => elevenLabsSupportedAudioFormats;

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
