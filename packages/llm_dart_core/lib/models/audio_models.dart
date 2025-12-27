/// Audio-related models for Text-to-Speech (TTS) and Speech-to-Text (STT) functionality
library;

import '../core/capability.dart' show UsageInfo;

/// Audio processing mode for different use cases
enum AudioProcessingMode {
  /// Standard batch processing
  batch,

  /// Streaming processing for real-time applications
  streaming,

  /// Real-time processing with minimal latency
  realtime,
}

/// Audio quality settings
enum AudioQuality {
  /// Low quality, smaller file size
  low,

  /// Standard quality, balanced size and quality
  standard,

  /// High quality, larger file size
  high,

  /// Ultra high quality, maximum file size
  ultra,
}

/// Audio format enumeration for better type safety
enum AudioFormat {
  /// MP3 format
  mp3,

  /// WAV format
  wav,

  /// OGG format
  ogg,

  /// OPUS format
  opus,

  /// AAC format
  aac,

  /// FLAC format
  flac,

  /// PCM format
  pcm,

  /// WebM format
  webm,

  /// M4A format
  m4a,
}

extension AudioFormatExtension on AudioFormat {
  /// Get the string representation of the audio format
  String get value {
    switch (this) {
      case AudioFormat.mp3:
        return 'mp3';
      case AudioFormat.wav:
        return 'wav';
      case AudioFormat.ogg:
        return 'ogg';
      case AudioFormat.opus:
        return 'opus';
      case AudioFormat.aac:
        return 'aac';
      case AudioFormat.flac:
        return 'flac';
      case AudioFormat.pcm:
        return 'pcm';
      case AudioFormat.webm:
        return 'webm';
      case AudioFormat.m4a:
        return 'm4a';
    }
  }

  /// Get MIME type for the audio format
  String get mimeType {
    switch (this) {
      case AudioFormat.mp3:
        return 'audio/mpeg';
      case AudioFormat.wav:
        return 'audio/wav';
      case AudioFormat.ogg:
        return 'audio/ogg';
      case AudioFormat.opus:
        return 'audio/opus';
      case AudioFormat.aac:
        return 'audio/aac';
      case AudioFormat.flac:
        return 'audio/flac';
      case AudioFormat.pcm:
        return 'audio/pcm';
      case AudioFormat.webm:
        return 'audio/webm';
      case AudioFormat.m4a:
        return 'audio/mp4';
    }
  }

  /// Create AudioFormat from string
  static AudioFormat fromString(String format) {
    switch (format.toLowerCase()) {
      case 'mp3':
        return AudioFormat.mp3;
      case 'wav':
        return AudioFormat.wav;
      case 'ogg':
        return AudioFormat.ogg;
      case 'opus':
        return AudioFormat.opus;
      case 'aac':
        return AudioFormat.aac;
      case 'flac':
        return AudioFormat.flac;
      case 'pcm':
        return AudioFormat.pcm;
      case 'webm':
        return AudioFormat.webm;
      case 'm4a':
        return AudioFormat.m4a;
      default:
        throw ArgumentError('Unsupported audio format: $format');
    }
  }
}

/// Timestamp granularity for audio processing
enum TimestampGranularity {
  /// No timestamps
  none,

  /// Word-level timestamps
  word,

  /// Character-level timestamps
  character,

  /// Segment-level timestamps
  segment,
}

/// Text normalization mode for TTS
enum TextNormalization {
  /// Automatic normalization
  auto,

  /// Always apply normalization
  on,

  /// Never apply normalization
  off,
}

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
                json['normalized_alignment'] as Map<String, dynamic>)
            : null,
        requestId: json['request_id'] as String?,
      );
}

/// Speech-to-Text request configuration
class STTRequest {
  /// Audio data as bytes (for direct audio input)
  final List<int>? audioData;

  /// File path (for file input)
  final String? filePath;

  /// Cloud storage URL (ElevenLabs specific)
  final String? cloudStorageUrl;

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

  const STTRequest({
    this.audioData,
    this.filePath,
    this.cloudStorageUrl,
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
  });

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

  /// Create STT request from cloud storage URL (ElevenLabs specific)
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
      STTRequest(
        cloudStorageUrl: cloudStorageUrl,
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
        if (cloudStorageUrl != null) 'cloud_storage_url': cloudStorageUrl,
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
        cloudStorageUrl: json['cloud_storage_url'] as String?,
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
                .map((s) =>
                    TranscriptionSegment.fromJson(s as Map<String, dynamic>))
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

/// Word timing information for STT
class WordTiming {
  /// The word text
  final String word;

  /// Start time in seconds
  final double start;

  /// End time in seconds
  final double end;

  /// Confidence score for this word (0.0-1.0)
  final double? confidence;

  const WordTiming({
    required this.word,
    required this.start,
    required this.end,
    this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'start': start,
        'end': end,
        if (confidence != null) 'confidence': confidence,
      };

  factory WordTiming.fromJson(Map<String, dynamic> json) => WordTiming(
        word: json['word'] as String,
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        confidence: json['confidence'] as double?,
      );
}

/// Voice information
class VoiceInfo {
  /// Voice ID
  final String id;

  /// Voice name
  final String name;

  /// Voice description
  final String? description;

  /// Voice category (e.g., 'premade', 'cloned')
  final String? category;

  /// Voice gender
  final String? gender;

  /// Voice accent/language
  final String? accent;

  /// Preview URL if available
  final String? previewUrl;

  const VoiceInfo({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.gender,
    this.accent,
    this.previewUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (gender != null) 'gender': gender,
        if (accent != null) 'accent': accent,
        if (previewUrl != null) 'preview_url': previewUrl,
      };

  factory VoiceInfo.fromJson(Map<String, dynamic> json) => VoiceInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
        gender: json['gender'] as String?,
        accent: json['accent'] as String?,
        previewUrl: json['preview_url'] as String?,
      );
}

/// Language information for STT
class LanguageInfo {
  /// Language code (e.g., 'en-US')
  final String code;

  /// Language name
  final String name;

  /// Whether this language is supported for real-time STT
  final bool supportsRealtime;

  const LanguageInfo({
    required this.code,
    required this.name,
    this.supportsRealtime = false,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'supports_realtime': supportsRealtime,
      };

  factory LanguageInfo.fromJson(Map<String, dynamic> json) => LanguageInfo(
        code: json['code'] as String,
        name: json['name'] as String,
        supportsRealtime: json['supports_realtime'] as bool? ?? false,
      );
}

/// Character-level timing alignment for TTS (ElevenLabs specific)
class AudioAlignment {
  /// List of characters
  final List<String> characters;

  /// Start times for each character in seconds
  final List<double> characterStartTimes;

  /// End times for each character in seconds
  final List<double> characterEndTimes;

  const AudioAlignment({
    required this.characters,
    required this.characterStartTimes,
    required this.characterEndTimes,
  });

  Map<String, dynamic> toJson() => {
        'characters': characters,
        'character_start_times_seconds': characterStartTimes,
        'character_end_times_seconds': characterEndTimes,
      };

  factory AudioAlignment.fromJson(Map<String, dynamic> json) => AudioAlignment(
        characters: List<String>.from(json['characters'] as List),
        characterStartTimes: List<double>.from(
          (json['character_start_times_seconds'] as List)
              .map((e) => (e as num).toDouble()),
        ),
        characterEndTimes: List<double>.from(
          (json['character_end_times_seconds'] as List)
              .map((e) => (e as num).toDouble()),
        ),
      );
}

/// Audio stream event for streaming TTS
abstract class AudioStreamEvent {
  const AudioStreamEvent();
}

/// Audio data chunk event
class AudioDataEvent extends AudioStreamEvent {
  /// Audio data chunk
  final List<int> data;

  /// Whether this is the final chunk
  final bool isFinal;

  const AudioDataEvent({
    required this.data,
    this.isFinal = false,
  });
}

/// Audio metadata event
class AudioMetadataEvent extends AudioStreamEvent {
  /// Content type
  final String? contentType;

  /// Sample rate
  final int? sampleRate;

  /// Duration in seconds
  final double? duration;

  const AudioMetadataEvent({
    this.contentType,
    this.sampleRate,
    this.duration,
  });
}

/// Audio timing event for character-level alignment
class AudioTimingEvent extends AudioStreamEvent {
  /// Character being spoken
  final String character;

  /// Start time in seconds
  final double startTime;

  /// End time in seconds
  final double endTime;

  const AudioTimingEvent({
    required this.character,
    required this.startTime,
    required this.endTime,
  });
}

/// Audio error event
class AudioErrorEvent extends AudioStreamEvent {
  /// Error message
  final String message;

  /// Error code if available
  final String? code;

  const AudioErrorEvent({
    required this.message,
    this.code,
  });
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

/// Transcription segment information (OpenAI specific)
class TranscriptionSegment {
  /// Unique identifier of the segment
  final int id;

  /// Seek offset of the segment
  final int seek;

  /// Start time of the segment in seconds
  final double start;

  /// End time of the segment in seconds
  final double end;

  /// Text content of the segment
  final String text;

  /// Array of token IDs for the text content
  final List<int> tokens;

  /// Temperature parameter used for generating the segment
  final double temperature;

  /// Average logprob of the segment
  final double avgLogprob;

  /// Compression ratio of the segment
  final double compressionRatio;

  /// Probability of no speech in the segment
  final double noSpeechProb;

  const TranscriptionSegment({
    required this.id,
    required this.seek,
    required this.start,
    required this.end,
    required this.text,
    required this.tokens,
    required this.temperature,
    required this.avgLogprob,
    required this.compressionRatio,
    required this.noSpeechProb,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'seek': seek,
        'start': start,
        'end': end,
        'text': text,
        'tokens': tokens,
        'temperature': temperature,
        'avg_logprob': avgLogprob,
        'compression_ratio': compressionRatio,
        'no_speech_prob': noSpeechProb,
      };

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) =>
      TranscriptionSegment(
        id: json['id'] as int,
        seek: json['seek'] as int,
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        text: json['text'] as String,
        tokens: List<int>.from(json['tokens'] as List),
        temperature: (json['temperature'] as num).toDouble(),
        avgLogprob: (json['avg_logprob'] as num).toDouble(),
        compressionRatio: (json['compression_ratio'] as num).toDouble(),
        noSpeechProb: (json['no_speech_prob'] as num).toDouble(),
      );
}

/// Enhanced word timing with speaker information (ElevenLabs specific)
class EnhancedWordTiming extends WordTiming {
  /// Type of the word (word, spacing, punctuation)
  final String? type;

  /// Log probability of the word
  final double? logprob;

  /// Speaker ID if diarization is enabled
  final String? speakerId;

  const EnhancedWordTiming({
    required super.word,
    required super.start,
    required super.end,
    super.confidence,
    this.type,
    this.logprob,
    this.speakerId,
  });

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        if (type != null) 'type': type,
        if (logprob != null) 'logprob': logprob,
        if (speakerId != null) 'speaker_id': speakerId,
      };

  factory EnhancedWordTiming.fromJson(Map<String, dynamic> json) =>
      EnhancedWordTiming(
        word: json['word'] as String,
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        confidence: json['confidence'] as double?,
        type: json['type'] as String?,
        logprob: json['logprob'] as double?,
        speakerId: json['speaker_id'] as String?,
      );
}
