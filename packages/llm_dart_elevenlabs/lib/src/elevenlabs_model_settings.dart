import 'package:llm_dart_provider/llm_dart_provider.dart';

/// Provider-owned model settings for package-owned ElevenLabs speech models.
final class ElevenLabsSpeechModelSettings implements ProviderModelOptions {
  final Map<String, String> headers;
  final String? defaultVoiceId;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  const ElevenLabsSpeechModelSettings({
    this.headers = const {},
    this.defaultVoiceId,
    this.stability,
    this.similarityBoost,
    this.style,
    this.useSpeakerBoost,
  });
}

/// Provider-owned model settings for package-owned ElevenLabs transcription models.
final class ElevenLabsTranscriptionModelSettings
    implements ProviderModelOptions {
  final Map<String, String> headers;

  const ElevenLabsTranscriptionModelSettings({
    this.headers = const {},
  });
}
