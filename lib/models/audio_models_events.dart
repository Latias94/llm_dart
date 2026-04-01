part of 'audio_models.dart';

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
