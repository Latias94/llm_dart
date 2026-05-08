part of 'audio_models.dart';

/// Text-to-Speech request configuration
class TTSRequest {
  /// Text to convert to speech
  final String text;

  /// Voice ID or name
  final String? voice;

  /// Model to use for TTS
  final String? model;

  /// Audio format (mp3, wav, ogg, etc.)
  final String? format;

  /// Sample rate (e.g., 44100, 22050)
  final int? sampleRate;

  /// Speed/rate of speech (provider-specific)
  final double? speed;

  /// Language code for TTS (ISO 639-1)
  final String? languageCode;

  /// Provider-owned invocation options.
  final ProviderInvocationOptions? providerOptions;

  const TTSRequest({
    required this.text,
    this.voice,
    this.model,
    this.format,
    this.sampleRate,
    this.speed,
    this.languageCode,
    this.providerOptions,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        if (voice != null) 'voice': voice,
        if (model != null) 'model': model,
        if (format != null) 'format': format,
        if (sampleRate != null) 'sample_rate': sampleRate,
        if (speed != null) 'speed': speed,
        if (languageCode != null) 'language_code': languageCode,
      };

  factory TTSRequest.fromJson(Map<String, dynamic> json) => TTSRequest(
        text: json['text'] as String,
        voice: json['voice'] as String?,
        model: json['model'] as String?,
        format: json['format'] as String?,
        sampleRate: json['sample_rate'] as int?,
        speed: json['speed'] as double?,
        languageCode: json['language_code'] as String?,
      );
}

/// Text-to-Speech response with metadata
class TTSResponse {
  /// Audio data as bytes
  final List<int> audioData;

  /// Content type (e.g., 'audio/mpeg')
  final String? contentType;

  /// Audio duration in seconds
  final double? duration;

  /// Sample rate
  final int? sampleRate;

  /// Voice used for generation
  final String? voice;

  /// Model used for generation
  final String? model;

  /// Usage information if available
  final UsageInfo? usage;

  /// Provider-owned response metadata.
  final ProviderMetadata? providerMetadata;

  const TTSResponse({
    required this.audioData,
    this.contentType,
    this.duration,
    this.sampleRate,
    this.voice,
    this.model,
    this.usage,
    this.providerMetadata,
  });

  Map<String, dynamic> toJson() => {
        'audio_data': audioData,
        if (contentType != null) 'content_type': contentType,
        if (duration != null) 'duration': duration,
        if (sampleRate != null) 'sample_rate': sampleRate,
        if (voice != null) 'voice': voice,
        if (model != null) 'model': model,
        if (usage != null) 'usage': usage!.toJson(),
        if (providerMetadata != null)
          'provider_metadata': providerMetadata!.toJsonMap(),
      };

  factory TTSResponse.fromJson(Map<String, dynamic> json) => TTSResponse(
        audioData: List<int>.from(json['audio_data'] as List),
        contentType: json['content_type'] as String?,
        duration: json['duration'] as double?,
        sampleRate: json['sample_rate'] as int?,
        voice: json['voice'] as String?,
        model: json['model'] as String?,
        usage: json['usage'] != null
            ? UsageInfo.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        providerMetadata: _providerMetadataFromJson(json),
      );
}
