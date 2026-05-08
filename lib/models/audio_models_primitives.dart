part of 'audio_models.dart';

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
