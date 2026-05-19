import 'package:llm_dart_provider/llm_dart_provider.dart';

const elevenLabsDefaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';

/// Provider-owned text-normalization modes for ElevenLabs speech generation.
enum ElevenLabsTextNormalization {
  auto,
  on,
  off,
}

/// Provider-owned pronunciation dictionary locator for ElevenLabs speech.
final class ElevenLabsPronunciationDictionaryLocator {
  final String pronunciationDictionaryId;
  final String? versionId;

  const ElevenLabsPronunciationDictionaryLocator({
    required this.pronunciationDictionaryId,
    this.versionId,
  });
}

/// Provider-owned invocation options for ElevenLabs speech generation.
final class ElevenLabsSpeechOptions implements ProviderInvocationOptions {
  final String? outputFormat;
  final String? languageCode;
  final double? speed;
  final List<ElevenLabsPronunciationDictionaryLocator>
      pronunciationDictionaryLocators;
  final int? seed;
  final String? previousText;
  final String? nextText;
  final List<String> previousRequestIds;
  final List<String> nextRequestIds;
  final ElevenLabsTextNormalization? textNormalization;
  final bool? applyLanguageTextNormalization;
  final bool? enableLogging;
  final int? optimizeStreamingLatency;
  final double? stability;
  final double? similarityBoost;
  final double? style;
  final bool? useSpeakerBoost;

  const ElevenLabsSpeechOptions({
    this.outputFormat,
    this.languageCode,
    this.speed,
    this.pronunciationDictionaryLocators = const [],
    this.seed,
    this.previousText,
    this.nextText,
    this.previousRequestIds = const [],
    this.nextRequestIds = const [],
    this.textNormalization,
    this.applyLanguageTextNormalization,
    this.enableLogging,
    this.optimizeStreamingLatency,
    this.stability,
    this.similarityBoost,
    this.style,
    this.useSpeakerBoost,
  });
}
