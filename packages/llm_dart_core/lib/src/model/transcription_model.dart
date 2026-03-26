import '../common/provider_metadata.dart';
import '../common/provider_options.dart';

final class TranscriptionRequest {
  final List<int> audioBytes;
  final String? mediaType;
  final ProviderInvocationOptions? providerOptions;

  const TranscriptionRequest({
    required this.audioBytes,
    this.mediaType,
    this.providerOptions,
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
