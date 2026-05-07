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

  /// Temperature for transcription (provider-specific)
  final double? temperature;

  /// Timestamp granularity (word, character, segment)
  final TimestampGranularity timestampGranularity;

  /// Whether to enable speaker diarization (ElevenLabs specific)
  final bool diarize;

  /// Maximum number of speakers (ElevenLabs specific)
  final int? numSpeakers;

  /// Whether to tag audio events like (laughter) (ElevenLabs specific)
  final bool tagAudioEvents;

  /// Whether to use webhook for async processing (ElevenLabs specific)
  final bool webhook;

  /// Prompt to guide transcription style (OpenAI specific)
  final String? prompt;

  /// Response format (json, text, srt, verbose_json, vtt)
  final String? responseFormat;

  /// Enable logging (ElevenLabs specific)
  final bool enableLogging;

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
    this.temperature,
    this.timestampGranularity = TimestampGranularity.word,
    this.diarize = false,
    this.numSpeakers,
    this.tagAudioEvents = true,
    this.webhook = false,
    this.prompt,
    this.responseFormat,
    this.enableLogging = true,
  }) : sourceUrl = sourceUrl ?? cloudStorageUrl;

  /// Create STT request from audio data
  factory STTRequest.fromAudio(
    List<int> audioData, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    double? temperature,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    bool diarize = false,
    int? numSpeakers,
    bool tagAudioEvents = true,
    bool webhook = false,
    String? prompt,
    String? responseFormat,
    bool enableLogging = true,
  }) =>
      STTRequest(
        audioData: audioData,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        temperature: temperature,
        timestampGranularity: timestampGranularity,
        diarize: diarize,
        numSpeakers: numSpeakers,
        tagAudioEvents: tagAudioEvents,
        webhook: webhook,
        prompt: prompt,
        responseFormat: responseFormat,
        enableLogging: enableLogging,
      );

  /// Create STT request from file
  factory STTRequest.fromFile(
    String filePath, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    double? temperature,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    bool diarize = false,
    int? numSpeakers,
    bool tagAudioEvents = true,
    bool webhook = false,
    String? prompt,
    String? responseFormat,
    bool enableLogging = true,
  }) =>
      STTRequest(
        filePath: filePath,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        temperature: temperature,
        timestampGranularity: timestampGranularity,
        diarize: diarize,
        numSpeakers: numSpeakers,
        tagAudioEvents: tagAudioEvents,
        webhook: webhook,
        prompt: prompt,
        responseFormat: responseFormat,
        enableLogging: enableLogging,
      );

  /// Create STT request from source URL
  factory STTRequest.fromSourceUrl(
    String sourceUrl, {
    String? model,
    String? language,
    String? format,
    bool includeWordTiming = false,
    bool includeConfidence = false,
    double? temperature,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    bool diarize = false,
    int? numSpeakers,
    bool tagAudioEvents = true,
    bool webhook = false,
    String? prompt,
    String? responseFormat,
    bool enableLogging = true,
  }) =>
      STTRequest(
        sourceUrl: sourceUrl,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        temperature: temperature,
        timestampGranularity: timestampGranularity,
        diarize: diarize,
        numSpeakers: numSpeakers,
        tagAudioEvents: tagAudioEvents,
        webhook: webhook,
        prompt: prompt,
        responseFormat: responseFormat,
        enableLogging: enableLogging,
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
    double? temperature,
    TimestampGranularity timestampGranularity = TimestampGranularity.word,
    bool diarize = false,
    int? numSpeakers,
    bool tagAudioEvents = true,
    bool webhook = false,
    String? prompt,
    String? responseFormat,
    bool enableLogging = true,
  }) =>
      STTRequest.fromSourceUrl(
        cloudStorageUrl,
        model: model,
        language: language,
        format: format,
        includeWordTiming: includeWordTiming,
        includeConfidence: includeConfidence,
        temperature: temperature,
        timestampGranularity: timestampGranularity,
        diarize: diarize,
        numSpeakers: numSpeakers,
        tagAudioEvents: tagAudioEvents,
        webhook: webhook,
        prompt: prompt,
        responseFormat: responseFormat,
        enableLogging: enableLogging,
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
        if (temperature != null) 'temperature': temperature,
        'timestamp_granularity': timestampGranularity.name,
        'diarize': diarize,
        if (numSpeakers != null) 'num_speakers': numSpeakers,
        'tag_audio_events': tagAudioEvents,
        'webhook': webhook,
        if (prompt != null) 'prompt': prompt,
        if (responseFormat != null) 'response_format': responseFormat,
        'enable_logging': enableLogging,
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
        temperature: json['temperature'] as double?,
        timestampGranularity: TimestampGranularity.values.firstWhere(
          (e) => e.name == json['timestamp_granularity'],
          orElse: () => TimestampGranularity.word,
        ),
        diarize: json['diarize'] as bool? ?? false,
        numSpeakers: json['num_speakers'] as int?,
        tagAudioEvents: json['tag_audio_events'] as bool? ?? true,
        webhook: json['webhook'] as bool? ?? false,
        prompt: json['prompt'] as String?,
        responseFormat: json['response_format'] as String?,
        enableLogging: json['enable_logging'] as bool? ?? true,
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

  /// Language probability (ElevenLabs specific)
  final double? languageProbability;

  /// Additional formats (ElevenLabs specific)
  final Map<String, dynamic>? additionalFormats;

  const STTResponse({
    required this.text,
    this.language,
    this.confidence,
    this.words,
    this.segments,
    this.model,
    this.duration,
    this.usage,
    this.languageProbability,
    this.additionalFormats,
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
        if (languageProbability != null)
          'language_probability': languageProbability,
        if (additionalFormats != null) 'additional_formats': additionalFormats,
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
        languageProbability: json['language_probability'] as double?,
        additionalFormats: json['additional_formats'] as Map<String, dynamic>?,
      );
}

/// Audio translation request (OpenAI specific)
class AudioTranslationRequest {
  /// Audio data as bytes (for direct audio input)
  final List<int>? audioData;

  /// File path (for file input)
  final String? filePath;

  /// Model to use for translation
  final String? model;

  /// Audio format hint
  final String? format;

  /// Prompt to guide translation style
  final String? prompt;

  /// Response format (json, text, srt, verbose_json, vtt)
  final String? responseFormat;

  /// Temperature for translation (0.0-1.0)
  final double? temperature;

  const AudioTranslationRequest({
    this.audioData,
    this.filePath,
    this.model,
    this.format,
    this.prompt,
    this.responseFormat,
    this.temperature,
  });

  /// Create translation request from audio data
  factory AudioTranslationRequest.fromAudio(
    List<int> audioData, {
    String? model,
    String? format,
    String? prompt,
    String? responseFormat,
    double? temperature,
  }) =>
      AudioTranslationRequest(
        audioData: audioData,
        model: model,
        format: format,
        prompt: prompt,
        responseFormat: responseFormat,
        temperature: temperature,
      );

  /// Create translation request from file
  factory AudioTranslationRequest.fromFile(
    String filePath, {
    String? model,
    String? format,
    String? prompt,
    String? responseFormat,
    double? temperature,
  }) =>
      AudioTranslationRequest(
        filePath: filePath,
        model: model,
        format: format,
        prompt: prompt,
        responseFormat: responseFormat,
        temperature: temperature,
      );

  Map<String, dynamic> toJson() => {
        if (audioData != null) 'audio_data': audioData,
        if (filePath != null) 'file_path': filePath,
        if (model != null) 'model': model,
        if (format != null) 'format': format,
        if (prompt != null) 'prompt': prompt,
        if (responseFormat != null) 'response_format': responseFormat,
        if (temperature != null) 'temperature': temperature,
      };

  factory AudioTranslationRequest.fromJson(Map<String, dynamic> json) =>
      AudioTranslationRequest(
        audioData: json['audio_data'] != null
            ? List<int>.from(json['audio_data'] as List)
            : null,
        filePath: json['file_path'] as String?,
        model: json['model'] as String?,
        format: json['format'] as String?,
        prompt: json['prompt'] as String?,
        responseFormat: json['response_format'] as String?,
        temperature: json['temperature'] as double?,
      );
}
