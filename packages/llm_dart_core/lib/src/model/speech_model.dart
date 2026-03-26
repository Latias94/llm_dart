import '../common/provider_metadata.dart';
import '../common/provider_options.dart';

final class SpeechGenerationRequest {
  final String text;
  final String? voice;
  final ProviderInvocationOptions? providerOptions;

  const SpeechGenerationRequest({
    required this.text,
    this.voice,
    this.providerOptions,
  });
}

final class SpeechGenerationResult {
  final List<int> audioBytes;
  final String? mediaType;
  final ProviderMetadata? providerMetadata;

  const SpeechGenerationResult({
    required this.audioBytes,
    this.mediaType,
    this.providerMetadata,
  });
}

abstract interface class SpeechModel {
  String get providerId;

  String get modelId;

  Future<SpeechGenerationResult> generateSpeech(
    SpeechGenerationRequest request,
  );
}
