import '../../../builder/llm_builder.dart';
import '../../../core/capability.dart';
import '../config/legacy_config_keys.dart';
import 'legacy_builder_provider_options.dart';

/// ElevenLabs-specific LLM builder with provider-specific configuration
/// methods.
///
/// This builder provides a layered configuration approach where
/// ElevenLabs-specific parameters are handled separately from the generic
/// LLMBuilder, keeping the main builder clean and focused.
///
/// Use this for ElevenLabs-specific parameters only. For common parameters like
/// apiKey, model, temperature, etc., continue using the base LLMBuilder
/// methods.
class ElevenLabsBuilder {
  final LLMBuilder _baseBuilder;
  final LegacyBuilderProviderOptionWriter _providerOptions;

  ElevenLabsBuilder(LLMBuilder baseBuilder)
      : _baseBuilder = baseBuilder,
        _providerOptions =
            LegacyBuilderProviderOptionWriter.elevenLabs(baseBuilder);

  /// Sets voice ID for ElevenLabs TTS.
  ElevenLabsBuilder voiceId(String voiceId) {
    _providerOptions.set(LegacyExtensionKeys.voiceId, voiceId);
    return this;
  }

  /// Sets stability parameter for ElevenLabs TTS (0.0-1.0).
  ElevenLabsBuilder stability(double stability) {
    _providerOptions.set(LegacyExtensionKeys.stability, stability);
    return this;
  }

  /// Sets similarity boost parameter for ElevenLabs TTS (0.0-1.0).
  ElevenLabsBuilder similarityBoost(double similarityBoost) {
    _providerOptions.set(
      LegacyExtensionKeys.similarityBoost,
      similarityBoost,
    );
    return this;
  }

  /// Sets style parameter for ElevenLabs TTS (0.0-1.0).
  ElevenLabsBuilder style(double style) {
    _providerOptions.set(LegacyExtensionKeys.style, style);
    return this;
  }

  /// Enables or disables speaker boost for ElevenLabs TTS.
  ElevenLabsBuilder useSpeakerBoost(bool enable) {
    _providerOptions.set(LegacyExtensionKeys.useSpeakerBoost, enable);
    return this;
  }

  /// Configure for high-quality speech with maximum stability.
  ElevenLabsBuilder forHighQuality() {
    return stability(1.0).similarityBoost(1.0).useSpeakerBoost(true).style(0.0);
  }

  /// Configure for expressive speech with more variability.
  ElevenLabsBuilder forExpressive() {
    return stability(0.3).similarityBoost(0.5).useSpeakerBoost(true).style(0.8);
  }

  /// Configure for balanced speech (recommended default).
  ElevenLabsBuilder forBalanced() {
    return stability(0.75)
        .similarityBoost(0.75)
        .useSpeakerBoost(true)
        .style(0.0);
  }

  /// Configure for natural conversational speech.
  ElevenLabsBuilder forConversational() {
    return stability(0.5).similarityBoost(0.8).useSpeakerBoost(true).style(0.2);
  }

  /// Builds and returns a configured LLM provider instance.
  Future<ChatCapability> build() async {
    return _baseBuilder.build();
  }

  /// Builds a provider with AudioCapability.
  Future<AudioCapability> buildAudio() async {
    return _baseBuilder.buildAudio();
  }
}
