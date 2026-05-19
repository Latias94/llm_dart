import 'package:llm_dart_provider/llm_dart_provider.dart';

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
