import '../../../../models/usage_models.dart';
import 'google_tts_models_response.dart';

/// Google TTS stream event base type.
abstract class GoogleTTSStreamEvent {
  const GoogleTTSStreamEvent();
}

/// Google TTS audio data event.
class GoogleTTSAudioDataEvent extends GoogleTTSStreamEvent {
  /// Audio data chunk.
  final List<int> data;

  /// Whether this is the final chunk.
  final bool isFinal;

  const GoogleTTSAudioDataEvent({
    required this.data,
    this.isFinal = false,
  });
}

/// Google TTS metadata event.
class GoogleTTSMetadataEvent extends GoogleTTSStreamEvent {
  /// Content type.
  final String? contentType;

  /// Model used.
  final String? model;

  /// Usage information.
  final UsageInfo? usage;

  const GoogleTTSMetadataEvent({
    this.contentType,
    this.model,
    this.usage,
  });
}

/// Google TTS error event.
class GoogleTTSErrorEvent extends GoogleTTSStreamEvent {
  /// Error message.
  final String message;

  /// Error code if available.
  final String? code;

  const GoogleTTSErrorEvent({
    required this.message,
    this.code,
  });
}

/// Google TTS completion event.
class GoogleTTSCompletionEvent extends GoogleTTSStreamEvent {
  /// Complete response.
  final GoogleTTSResponse response;

  const GoogleTTSCompletionEvent(this.response);
}
