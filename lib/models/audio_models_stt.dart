part of 'audio_models.dart';

/// Speech-to-Text request configuration
class STTRequest {
  /// Audio data as bytes (for direct audio input)
  final List<int>? audioData;

  /// File path (for file input)
  final String? filePath;

  /// Source URL for transcription input
  final String? sourceUrl;

  /// Model to use for STT
  final String? model;

  /// Language code (e.g., 'en-US')
  final String? language;

  /// Audio format hint
  final String? format;

  /// Whether to include word-level timing
  final bool includeWordTiming;

  /// Whether to include confidence scores
  final bool includeConfidence;

  /// Timestamp granularity (word, character, segment)
  final TimestampGranularity timestampGranularity;

  /// Provider-owned invocation options.
  final ProviderInvocationOptions? providerOptions;

  @Deprecated('Use sourceUrl instead.')
  String? get cloudStorageUrl => sourceUrl;

  const STTRequest({
    this.audioData,
    this.filePath,
    String? sourceUrl,
    @Deprecated('Use sourceUrl instead.') String? cloudStorageUrl,
    this.model,
    this.language,
    this.format,
    this.includeWordTiming = false,
    this.includeConfidence = false,
    this.timestampGranularity = TimestampGranularity.word,
    this.providerOptions,
  }) : sourceUrl = sourceUrl ?? cloudStorageUrl;

  /// Create STT request from audio data
  factory STTRequest.fromAudio(
    List<int> audioData, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    ProviderInvocationOptions? providerOptions,
  }) =>
      STTRequest(
        audioData: audioData,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        timestampGranularity: timestampGranularity,
        providerOptions: providerOptions,
      );

  /// Create STT request from file
  factory STTRequest.fromFile(
    String filePath, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    ProviderInvocationOptions? providerOptions,
  }) =>
      STTRequest(
        filePath: filePath,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        timestampGranularity: timestampGranularity,
        providerOptions: providerOptions,
      );

  /// Create STT request from source URL
  factory STTRequest.fromSourceUrl(
    String sourceUrl, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    ProviderInvocationOptions? providerOptions,
  }) =>
      STTRequest(
        sourceUrl: sourceUrl,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        timestampGranularity: timestampGranularity,
        providerOptions: providerOptions,
      );

  /// Create STT request from cloud storage URL
  @Deprecated('Use STTRequest.fromSourceUrl(...) instead.')
  factory STTRequest.fromCloudUrl(
    String cloudStorageUrl, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    ProviderInvocationOptions? providerOptions,
  }) =>
      STTRequest.fromSourceUrl(
        cloudStorageUrl,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        timestampGranularity: timestampGranularity,
        providerOptions: providerOptions,
      );

  Map<String, dynamic> toJson() => {
        if (audioData != null) 'audio_data': audioData,
        if (filePath != null) 'file_path': filePath,
        if (sourceUrl != null) 'source_url': sourceUrl,
        if (sourceUrl != null) 'cloud_storage_url': sourceUrl,
        if (model != null) 'model': model,
        if (language != null) 'language': language,
        if (format != null) 'format': format,
        'include_word_timing': includeWordTiming,
        'include_confidence': includeConfidence,
        'timestamp_granularity': timestampGranularity.name,
      };

  factory STTRequest.fromJson(Map<String, dynamic> json) => STTRequest(
        audioData: json['audio_data'] != null
            ? List<int>.from(json['audio_data'] as List)
            : null,
        filePath: json['file_path'] as String?,
        sourceUrl: json['source_url'] as String? ??
            json['cloud_storage_url'] as String?,
        model: json['model'] as String?,
        language: json['language'] as String?,
        format: json['format'] as String?,
        includeWordTiming: json['include_word_timing'] as bool? ?? false,
        includeConfidence: json['include_confidence'] as bool? ?? false,
        timestampGranularity: TimestampGranularity.values.firstWhere(
          (e) => e.name == json['timestamp_granularity'],
          orElse: () => TimestampGranularity.word,
        ),
      );
}

/// Speech-to-Text response with metadata
class STTResponse {
  /// Transcribed text
  final String text;

  /// Language code detected
  final String? language;

  /// Overall confidence score (0.0-1.0)
  final double? confidence;

  /// Word-level timing and confidence information
  final List<WordTiming>? words;

  /// Segment-level information (OpenAI specific)
  final List<TranscriptionSegment>? segments;

  /// Model used for transcription
  final String? model;

  /// Audio duration in seconds
  final double? duration;

  /// Usage information if available
  final UsageInfo? usage;

  /// Provider-owned response metadata.
  final ProviderMetadata? providerMetadata;

  const STTResponse({
    required this.text,
    this.language,
    this.confidence,
    this.words,
    this.segments,
    this.model,
    this.duration,
    this.usage,
    this.providerMetadata,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        if (language != null) 'language': language,
        if (confidence != null) 'confidence': confidence,
        if (words != null) 'words': words!.map((w) => w.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((s) => s.toJson()).toList(),
        if (model != null) 'model': model,
        if (duration != null) 'duration': duration,
        if (usage != null) 'usage': usage!.toJson(),
        if (providerMetadata != null)
          'provider_metadata': providerMetadata!.toJsonMap(),
      };

  factory STTResponse.fromJson(Map<String, dynamic> json) => STTResponse(
        text: json['text'] as String,
        language: json['language'] as String?,
        confidence: json['confidence'] as double?,
        words: json['words'] != null
            ? (json['words'] as List)
                .map((w) => WordTiming.fromJson(w as Map<String, dynamic>))
                .toList()
            : null,
        segments: json['segments'] != null
            ? (json['segments'] as List)
                .map(
                  (s) => TranscriptionSegment.fromJson(
                    s as Map<String, dynamic>,
                  ),
                )
                .toList()
            : null,
        model: json['model'] as String?,
        duration: json['duration'] as double?,
        usage: json['usage'] != null
            ? UsageInfo.fromJson(json['usage'] as Map<String, dynamic>)
            : null,
        providerMetadata: _providerMetadataFromJson(json),
      );
}
