import '../common/call_options.dart';
import '../common/provider_metadata.dart';

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

final class TranscriptionResult {
  final String text;
  final ProviderMetadata? providerMetadata;

  const TranscriptionResult({
    required this.text,
    this.providerMetadata,
  });
}

abstract interface class TranscriptionModel {
  String get providerId;

  String get modelId;

  Future<TranscriptionResult> transcribe(TranscriptionRequest request);
}
