import '../common/call_options.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import 'model_response_metadata.dart';

final class TranscriptionRequest {
  final List<int> audioBytes;
  final String? mediaType;
  final CallOptions callOptions;

  const TranscriptionRequest({
    required this.audioBytes,
    this.mediaType,
    this.callOptions = const CallOptions(),
  });
}

final class TranscriptionSegment {
  final String text;
  final double startSeconds;
  final double endSeconds;

  const TranscriptionSegment({
    required this.text,
    required this.startSeconds,
    required this.endSeconds,
  });
}

final class TranscriptionResult {
  final String text;
  final List<TranscriptionSegment> segments;
  final String? language;
  final double? durationSeconds;
  final List<ModelWarning> warnings;
  final ModelResponseMetadata? responseMetadata;
  final ProviderMetadata? providerMetadata;

  const TranscriptionResult({
    required this.text,
    this.segments = const [],
    this.language,
    this.durationSeconds,
    this.warnings = const [],
    this.responseMetadata,
    this.providerMetadata,
  });
}

abstract interface class TranscriptionModel {
  String get providerId;

  String get modelId;

  Future<TranscriptionResult> transcribe(TranscriptionRequest request);
}
