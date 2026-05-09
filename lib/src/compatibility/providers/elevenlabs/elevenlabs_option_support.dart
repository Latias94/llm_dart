import 'package:llm_dart_elevenlabs/llm_dart_elevenlabs.dart'
    as modern_elevenlabs;

modern_elevenlabs.ElevenLabsSpeechOptions? resolveElevenLabsSpeechOptions(
  Object? options,
) {
  if (options == null) {
    return null;
  }
  if (options is modern_elevenlabs.ElevenLabsSpeechOptions) {
    return options;
  }
  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected ElevenLabsSpeechOptions for ElevenLabs speech requests.',
  );
}

modern_elevenlabs.ElevenLabsTranscriptionOptions?
    resolveElevenLabsTranscriptionOptions(Object? options) {
  if (options == null) {
    return null;
  }
  if (options is modern_elevenlabs.ElevenLabsTranscriptionOptions) {
    return options;
  }
  throw ArgumentError.value(
    options,
    'providerOptions',
    'Expected ElevenLabsTranscriptionOptions for ElevenLabs transcription requests.',
  );
}
