import 'package:llm_dart_builder/llm_dart_builder.dart';
import 'package:llm_dart_core/core/capability.dart';

/// ElevenLabs-specific LLM builder.
///
/// This wrapper is provided by the **umbrella** `llm_dart` package. Provider
/// subpackages do not depend on `llm_dart_builder`.
class ElevenLabsBuilder {
  final LLMBuilder _baseBuilder;

  ElevenLabsBuilder(this._baseBuilder);

  ElevenLabsBuilder voiceId(String voiceId) {
    _baseBuilder.option('voiceId', voiceId);
    return this;
  }

  ElevenLabsBuilder stability(double stability) {
    _baseBuilder.option('stability', stability);
    return this;
  }

  ElevenLabsBuilder similarityBoost(double similarityBoost) {
    _baseBuilder.option('similarityBoost', similarityBoost);
    return this;
  }

  ElevenLabsBuilder style(double style) {
    _baseBuilder.option('style', style);
    return this;
  }

  ElevenLabsBuilder useSpeakerBoost(bool enable) {
    _baseBuilder.option('useSpeakerBoost', enable);
    return this;
  }

  Future<TextToSpeechCapability> buildSpeech() async =>
      _baseBuilder.buildSpeech();

  Future<StreamingTextToSpeechCapability> buildStreamingSpeech() async =>
      _baseBuilder.buildStreamingSpeech();

  Future<SpeechToTextCapability> buildTranscription() async =>
      _baseBuilder.buildTranscription();

  Future<AudioTranslationCapability> buildAudioTranslation() async =>
      _baseBuilder.buildAudioTranslation();

  Future<RealtimeAudioCapability> buildRealtimeAudio() async =>
      _baseBuilder.buildRealtimeAudio();

  Future<TextToSpeechCapability> build() async => buildSpeech();
}
