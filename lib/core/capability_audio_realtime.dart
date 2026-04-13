part of 'capability.dart';

/// Configuration for real-time audio sessions.
class RealtimeAudioConfig {
  /// Audio input format.
  final String? inputFormat;

  /// Audio output format.
  final String? outputFormat;

  /// Sample rate for audio processing.
  final int? sampleRate;

  /// Enable voice activity detection.
  final bool enableVAD;

  /// Enable echo cancellation.
  final bool enableEchoCancellation;

  /// Enable noise suppression.
  final bool enableNoiseSuppression;

  /// Session timeout in seconds.
  final int? timeoutSeconds;

  /// Custom session parameters.
  final Map<String, dynamic>? customParams;

  const RealtimeAudioConfig({
    this.inputFormat,
    this.outputFormat,
    this.sampleRate,
    this.enableVAD = true,
    this.enableEchoCancellation = true,
    this.enableNoiseSuppression = true,
    this.timeoutSeconds,
    this.customParams,
  });

  Map<String, dynamic> toJson() => {
        if (inputFormat != null) 'input_format': inputFormat,
        if (outputFormat != null) 'output_format': outputFormat,
        if (sampleRate != null) 'sample_rate': sampleRate,
        'enable_vad': enableVAD,
        'enable_echo_cancellation': enableEchoCancellation,
        'enable_noise_suppression': enableNoiseSuppression,
        if (timeoutSeconds != null) 'timeout_seconds': timeoutSeconds,
        if (customParams != null) 'custom_params': customParams,
      };

  factory RealtimeAudioConfig.fromJson(Map<String, dynamic> json) =>
      RealtimeAudioConfig(
        inputFormat: json['input_format'] as String?,
        outputFormat: json['output_format'] as String?,
        sampleRate: json['sample_rate'] as int?,
        enableVAD: json['enable_vad'] as bool? ?? true,
        enableEchoCancellation:
            json['enable_echo_cancellation'] as bool? ?? true,
        enableNoiseSuppression:
            json['enable_noise_suppression'] as bool? ?? true,
        timeoutSeconds: json['timeout_seconds'] as int?,
        customParams: json['custom_params'] as Map<String, dynamic>?,
      );
}

/// A stateful real-time audio session.
abstract class RealtimeAudioSession {
  /// Send audio data to the session.
  void sendAudio(List<int> audioData);

  /// Receive events from the session.
  Stream<RealtimeAudioEvent> get events;

  /// Close the session gracefully.
  Future<void> close();

  /// Check if the session is still active.
  bool get isActive;

  /// Session ID for tracking.
  String get sessionId;
}

/// Events from real-time audio sessions.
abstract class RealtimeAudioEvent {
  /// Timestamp of the event.
  final DateTime timestamp;

  const RealtimeAudioEvent({required this.timestamp});
}

/// Real-time transcription event.
class RealtimeTranscriptionEvent extends RealtimeAudioEvent {
  /// Transcribed text.
  final String text;

  /// Whether this is a final transcription.
  final bool isFinal;

  /// Confidence score.
  final double? confidence;

  const RealtimeTranscriptionEvent({
    required super.timestamp,
    required this.text,
    required this.isFinal,
    this.confidence,
  });
}

/// Real-time audio response event.
class RealtimeAudioResponseEvent extends RealtimeAudioEvent {
  /// Audio response data.
  final List<int> audioData;

  /// Whether this is the final chunk.
  final bool isFinal;

  const RealtimeAudioResponseEvent({
    required super.timestamp,
    required this.audioData,
    required this.isFinal,
  });
}

/// Real-time session status event.
class RealtimeSessionStatusEvent extends RealtimeAudioEvent {
  /// Session status.
  final String status;

  /// Additional status information.
  final Map<String, dynamic>? details;

  const RealtimeSessionStatusEvent({
    required super.timestamp,
    required this.status,
    this.details,
  });
}

/// Real-time error event.
class RealtimeErrorEvent extends RealtimeAudioEvent {
  /// Error message.
  final String message;

  /// Error code.
  final String? code;

  const RealtimeErrorEvent({
    required super.timestamp,
    required this.message,
    this.code,
  });
}
