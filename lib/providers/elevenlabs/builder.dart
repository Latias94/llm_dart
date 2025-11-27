import '../../builder/llm_builder.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// ElevenLabs-specific LLM builder with provider-specific configuration methods
///
/// This builder provides a layered configuration approach where ElevenLabs-specific
/// parameters are handled separately from the generic LLMBuilder, keeping the
/// main builder clean and focused.
///
/// Use this for ElevenLabs-specific parameters only. For common parameters like
/// apiKey, model, temperature, etc., continue using the base LLMBuilder methods.
class ElevenLabsBuilder {
  final LLMBuilder _baseBuilder;

  ElevenLabsBuilder(this._baseBuilder);

  // ========== ElevenLabs-specific configuration methods ==========

  /// Sets voice ID for ElevenLabs TTS
  ///
  /// The voice ID determines which voice will be used for text-to-speech.
  /// You can get available voice IDs using the `getVoices()` method.
  ///
  /// Example:
  /// ```dart
  /// final provider = await ai()
  ///     .elevenlabs((elevenlabs) => elevenlabs
  ///         .voiceId('21m00Tcm4TlvDq8ikWAM'))
  ///     .apiKey(apiKey)
  ///     .build();
  /// ```
  ElevenLabsBuilder voiceId(String voiceId) {
    _baseBuilder.extension(LLMConfigKeys.voiceId, voiceId);
    return this;
  }

  /// Sets stability parameter for ElevenLabs TTS (0.0-1.0)
  ///
  /// Controls the stability of the voice. Higher values make the voice more
  /// consistent but potentially less expressive. Lower values make it more
  /// variable and expressive but potentially less consistent.
  ///
  /// - 0.0: Maximum variability and expressiveness
  /// - 1.0: Maximum stability and consistency
  /// - Default: Usually around 0.75
  ElevenLabsBuilder stability(double stability) {
    _baseBuilder.extension(LLMConfigKeys.stability, stability);
    return this;
  }

  /// Sets similarity boost parameter for ElevenLabs TTS (0.0-1.0)
  ///
  /// Controls how closely the AI should adhere to the original voice.
  /// Higher values make the output more similar to the original voice,
  /// while lower values allow for more creative interpretation.
  ///
  /// - 0.0: Maximum creative freedom
  /// - 1.0: Maximum similarity to original voice
  /// - Default: Usually around 0.75
  ElevenLabsBuilder similarityBoost(double similarityBoost) {
    _baseBuilder.extension(LLMConfigKeys.similarityBoost, similarityBoost);
    return this;
  }

  /// Sets style parameter for ElevenLabs TTS (0.0-1.0)
  ///
  /// Controls the style exaggeration of the voice. Higher values make
  /// the voice more stylized and expressive, while lower values make
  /// it more neutral.
  ///
  /// - 0.0: Neutral, less stylized
  /// - 1.0: Maximum style exaggeration
  /// - Default: Usually around 0.0
  ElevenLabsBuilder style(double style) {
    _baseBuilder.extension(LLMConfigKeys.style, style);
    return this;
  }

  /// Enables or disables speaker boost for ElevenLabs TTS
  ///
  /// Speaker boost enhances the clarity and quality of the generated speech,
  /// particularly useful for longer texts or when clarity is important.
  ///
  /// - true: Enable speaker boost (recommended for most use cases)
  /// - false: Disable speaker boost
  /// - Default: true
  ElevenLabsBuilder useSpeakerBoost(bool enable) {
    _baseBuilder.extension(LLMConfigKeys.useSpeakerBoost, enable);
    return this;
  }

  // ========== Convenience methods for common configurations ==========

  /// Configure for high-quality speech with maximum stability
  ///
  /// Sets stability to 1.0, similarity boost to 1.0, and enables speaker boost.
  /// Best for professional narration, audiobooks, or formal presentations.
  ElevenLabsBuilder forHighQuality() {
    return stability(1.0).similarityBoost(1.0).useSpeakerBoost(true).style(0.0);
  }

  /// Configure for expressive speech with more variability
  ///
  /// Sets lower stability and similarity boost for more dynamic speech.
  /// Best for character voices, storytelling, or creative content.
  ElevenLabsBuilder forExpressive() {
    return stability(0.3).similarityBoost(0.5).useSpeakerBoost(true).style(0.8);
  }

  /// Configure for balanced speech (recommended default)
  ///
  /// Sets moderate values for all parameters, providing a good balance
  /// between stability and expressiveness.
  ElevenLabsBuilder forBalanced() {
    return stability(0.75)
        .similarityBoost(0.75)
        .useSpeakerBoost(true)
        .style(0.0);
  }

  /// Configure for natural conversational speech
  ///
  /// Optimized for dialogue, conversations, or interactive applications.
  ElevenLabsBuilder forConversational() {
    return stability(0.5).similarityBoost(0.8).useSpeakerBoost(true).style(0.2);
  }

  // ========== Build methods ==========

  /// Builds and returns a configured LLM provider instance
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with AudioCapability
  ///
  /// Returns a provider that implements AudioCapability for text-to-speech
  /// and other audio processing features.
  Future<AudioCapability> buildAudio() async {
    return _baseBuilder.buildAudio();
  }
}
