import 'package:llm_dart_provider/llm_dart_provider.dart';

const elevenLabsDefaultBaseUrl = 'https://api.elevenlabs.io/v1';
const elevenLabsDefaultVoiceId = 'JBFqnCBsd6RMkjVDRZzb';

/// Provider-owned text-normalization modes for ElevenLabs speech generation.
enum ElevenLabsTextNormalization {
  auto,
  on,
  off,
}

/// Provider-owned timestamp granularity for ElevenLabs transcription.
enum ElevenLabsTranscriptionTimestampGranularity {
  none,
  word,
  character,
}

/// Provider-owned file-format hint for ElevenLabs transcription.
enum ElevenLabsTranscriptionFileFormat {
  pcmS16le16,
  other,
}

extension ElevenLabsTranscriptionFileFormatValue
    on ElevenLabsTranscriptionFileFormat {
  String get value => switch (this) {
        ElevenLabsTranscriptionFileFormat.pcmS16le16 => 'pcm_s16le_16',
        ElevenLabsTranscriptionFileFormat.other => 'other',
      };
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

/// Provider-owned invocation options for ElevenLabs transcription requests.
final class ElevenLabsTranscriptionOptions
    implements ProviderInvocationOptions {
  final String? languageCode;
  final bool? tagAudioEvents;
  final int? numSpeakers;
  final ElevenLabsTranscriptionTimestampGranularity? timestampGranularity;
  final bool? diarize;
  final ElevenLabsTranscriptionFileFormat? fileFormat;
  final bool? enableLogging;

  const ElevenLabsTranscriptionOptions({
    this.languageCode,
    this.tagAudioEvents,
    this.numSpeakers,
    this.timestampGranularity,
    this.diarize,
    this.fileFormat,
    this.enableLogging,
  });
}
