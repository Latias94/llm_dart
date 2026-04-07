import 'package:llm_dart_transport/llm_dart_transport.dart'
    show DioClientOverrides, DioTransportClient, ImmutableDioClientOverrides;

import '../../core/config.dart';
import '../../src/config/legacy_config_extensions.dart';
import 'defaults.dart';

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
  final DioClientOverrides? dioOverrides;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  /// Reference to original LLMConfig for accessing extensions
  final LLMConfig? _originalConfig;

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
    LLMConfig? originalConfig,
  }) : _originalConfig = originalConfig;

  /// Create ElevenLabsConfig from unified LLMConfig
  factory ElevenLabsConfig.fromLLMConfig(LLMConfig config) {
    return ElevenLabsConfig(
      apiKey: config.apiKey!,
      baseUrl: config.baseUrl,
      model: config.model,
      timeout: config.timeout,
      dioOverrides: _legacyDioOverridesFromConfig(config),
      // ElevenLabs-specific extensions
      voiceId: config.getExtension<String>(LegacyExtensionKeys.voiceId),
      stability: config.getExtension<double>(LegacyExtensionKeys.stability),
      similarityBoost:
          config.getExtension<double>(LegacyExtensionKeys.similarityBoost),
      style: config.getExtension<double>(LegacyExtensionKeys.style),
      useSpeakerBoost:
          config.getExtension<bool>(LegacyExtensionKeys.useSpeakerBoost),
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
        originalConfig: _originalConfig,
      );
}

DioClientOverrides? _legacyDioOverridesFromConfig(LLMConfig config) {
  final customTransport = config.legacyTransportClient;
  final customDio = switch (customTransport) {
    DioTransportClient(:final dio) => dio,
    _ => config.legacyCustomDio,
  };

  if (customDio == null &&
      config.legacyCustomHeaders.isEmpty &&
      !config.legacyEnableHttpLogging &&
      config.legacyHttpProxy == null &&
      !config.legacyBypassSslVerification &&
      config.legacySslCertificatePath == null &&
      config.legacyConnectionTimeout == null &&
      config.legacyReceiveTimeout == null &&
      config.legacySendTimeout == null) {
    return null;
  }

  return ImmutableDioClientOverrides(
    customDio: customDio,
    customHeaders: config.legacyCustomHeaders,
    enableHttpLogging: config.legacyEnableHttpLogging,
    proxyUrl: config.legacyHttpProxy,
    bypassSslVerification: config.legacyBypassSslVerification,
    certificatePath: config.legacySslCertificatePath,
    connectionTimeout: config.legacyConnectionTimeout,
    receiveTimeout: config.legacyReceiveTimeout,
    sendTimeout: config.legacySendTimeout,
    timeout: config.timeout,
  );
}
