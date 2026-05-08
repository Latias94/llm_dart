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

  /// Audio quality/bitrate
  final String? quality;

  /// Sample rate (e.g., 44100, 22050)
  final int? sampleRate;

  /// Voice stability (0.0-1.0, provider-specific)
  final double? stability;

  /// Similarity boost (0.0-1.0, provider-specific)
  final double? similarityBoost;

  /// Style parameter (0.0-1.0, provider-specific)
  final double? style;

  /// Use speaker boost (provider-specific)
  final bool? useSpeakerBoost;

  /// Speed/rate of speech (provider-specific)
  final double? speed;

  /// Processing mode (batch, streaming, realtime)
  final AudioProcessingMode processingMode;

  /// Whether to include timing information
  final bool includeTimestamps;

  /// Timestamp granularity (word, character, segment)
  final TimestampGranularity timestampGranularity;

  /// Text normalization mode
  final TextNormalization textNormalization;

  /// Language code for TTS (ISO 639-1)
  final String? languageCode;

  /// Instructions for voice control (OpenAI specific)
  final String? instructions;

  /// Previous text for continuity (ElevenLabs specific)
  final String? previousText;

  /// Next text for continuity (ElevenLabs specific)
  final String? nextText;

  /// Previous request IDs for continuity (ElevenLabs specific)
  final List<String>? previousRequestIds;

  /// Next request IDs for continuity (ElevenLabs specific)
  final List<String>? nextRequestIds;

  /// Seed for deterministic generation
  final int? seed;

  /// Enable logging (ElevenLabs specific)
  final bool enableLogging;

  /// Optimize streaming latency (ElevenLabs specific)
  final int? optimizeStreamingLatency;

  /// Provider-owned invocation options.
  final ProviderInvocationOptions? providerOptions;

  const TTSRequest({
    required this.text,
    this.voice,
    this.model,
    this.format,
    this.quality,
    this.sampleRate,
    this.stability,
    this.similarityBoost,
    this.style,
    this.useSpeakerBoost,
    this.speed,
    this.processingMode = AudioProcessingMode.batch,
    this.includeTimestamps = false,
    this.timestampGranularity = TimestampGranularity.word,
    this.textNormalization = TextNormalization.auto,
    this.languageCode,
    this.instructions,
    this.previousText,
    this.nextText,
    this.previousRequestIds,
    this.nextRequestIds,
    this.seed,
    this.enableLogging = true,
    this.optimizeStreamingLatency,
    this.providerOptions,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        if (voice != null) 'voice': voice,
        if (model != null) 'model': model,
        if (format != null) 'format': format,
        if (quality != null) 'quality': quality,
        if (sampleRate != null) 'sample_rate': sampleRate,
        if (stability != null) 'stability': stability,
        if (similarityBoost != null) 'similarity_boost': similarityBoost,
        if (style != null) 'style': style,
        if (useSpeakerBoost != null) 'use_speaker_boost': useSpeakerBoost,
        if (speed != null) 'speed': speed,
        'processing_mode': processingMode.name,
        'include_timestamps': includeTimestamps,
        'timestamp_granularity': timestampGranularity.name,
        'text_normalization': textNormalization.name,
        if (languageCode != null) 'language_code': languageCode,
        if (instructions != null) 'instructions': instructions,
        if (previousText != null) 'previous_text': previousText,
        if (nextText != null) 'next_text': nextText,
        if (previousRequestIds != null)
          'previous_request_ids': previousRequestIds,
        if (nextRequestIds != null) 'next_request_ids': nextRequestIds,
        if (seed != null) 'seed': seed,
        'enable_logging': enableLogging,
        if (optimizeStreamingLatency != null)
          'optimize_streaming_latency': optimizeStreamingLatency,
      };

  factory TTSRequest.fromJson(Map<String, dynamic> json) => TTSRequest(
        text: json['text'] as String,
        voice: json['voice'] as String?,
        model: json['model'] as String?,
        format: json['format'] as String?,
        quality: json['quality'] as String?,
        sampleRate: json['sample_rate'] as int?,
        stability: json['stability'] as double?,
        similarityBoost: json['similarity_boost'] as double?,
        style: json['style'] as double?,
        useSpeakerBoost: json['use_speaker_boost'] as bool?,
        speed: json['speed'] as double?,
        processingMode: AudioProcessingMode.values.firstWhere(
          (e) => e.name == json['processing_mode'],
          orElse: () => AudioProcessingMode.batch,
        ),
        includeTimestamps: json['include_timestamps'] as bool? ?? false,
        timestampGranularity: TimestampGranularity.values.firstWhere(
          (e) => e.name == json['timestamp_granularity'],
          orElse: () => TimestampGranularity.word,
        ),
        textNormalization: TextNormalization.values.firstWhere(
          (e) => e.name == json['text_normalization'],
          orElse: () => TextNormalization.auto,
        ),
        languageCode: json['language_code'] as String?,
        instructions: json['instructions'] as String?,
        previousText: json['previous_text'] as String?,
        nextText: json['next_text'] as String?,
        previousRequestIds: json['previous_request_ids'] != null
            ? List<String>.from(json['previous_request_ids'] as List)
            : null,
        nextRequestIds: json['next_request_ids'] != null
            ? List<String>.from(json['next_request_ids'] as List)
            : null,
        seed: json['seed'] as int?,
        enableLogging: json['enable_logging'] as bool? ?? true,
        optimizeStreamingLatency: json['optimize_streaming_latency'] as int?,
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

  /// Character-level timing alignment (ElevenLabs specific)
  final AudioAlignment? alignment;

  /// Normalized character-level timing alignment (ElevenLabs specific)
  final AudioAlignment? normalizedAlignment;

  /// Request ID for continuity (ElevenLabs specific)
  final String? requestId;

  const TTSResponse({
    required this.audioData,
    this.contentType,
    this.duration,
    this.sampleRate,
    this.voice,
    this.model,
    this.usage,
    this.alignment,
    this.normalizedAlignment,
    this.requestId,
  });

  Map<String, dynamic> toJson() => {
        'audio_data': audioData,
        if (contentType != null) 'content_type': contentType,
        if (duration != null) 'duration': duration,
        if (sampleRate != null) 'sample_rate': sampleRate,
        if (voice != null) 'voice': voice,
        if (model != null) 'model': model,
        if (usage != null) 'usage': usage!.toJson(),
        if (alignment != null) 'alignment': alignment!.toJson(),
        if (normalizedAlignment != null)
          'normalized_alignment': normalizedAlignment!.toJson(),
        if (requestId != null) 'request_id': requestId,
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
        alignment: json['alignment'] != null
            ? AudioAlignment.fromJson(json['alignment'] as Map<String, dynamic>)
            : null,
        normalizedAlignment: json['normalized_alignment'] != null
            ? AudioAlignment.fromJson(
                json['normalized_alignment'] as Map<String, dynamic>,
              )
            : null,
        requestId: json['request_id'] as String?,
      );
}
