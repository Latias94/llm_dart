part of 'audio_models.dart';

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
