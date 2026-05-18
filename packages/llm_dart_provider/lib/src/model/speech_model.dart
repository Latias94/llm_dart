import '../common/call_options.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import 'model_response_metadata.dart';

final class SpeechGenerationRequest {
  final String text;
  final String? voice;
  final String? outputFormat;
  final String? instructions;
  final double? speed;
  final String? language;
  final CallOptions callOptions;

  const SpeechGenerationRequest({
    required this.text,
    this.voice,
    this.outputFormat,
    this.instructions,
    this.speed,
    this.language,
    this.callOptions = const CallOptions(),
  });
}

final class SpeechGenerationResult {
  final List<int> audioBytes;
  final String? mediaType;
  final List<ModelWarning> warnings;
  final ModelResponseMetadata? responseMetadata;
  final ProviderMetadata? providerMetadata;

  const SpeechGenerationResult({
    required this.audioBytes,
    this.mediaType,
    this.warnings = const [],
    this.responseMetadata,
    this.providerMetadata,
  });
}

abstract interface class SpeechModel {
  String get providerId;

  String get modelId;

  Future<SpeechGenerationResult> doGenerate(
    SpeechGenerationRequest request,
  );
}
