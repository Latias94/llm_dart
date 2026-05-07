import '../src/compatibility/config/legacy_config_keys.dart';

/// Audio configuration builder for LLM providers
class AudioConfig {
  final Map<String, dynamic> _config = {};

  /// Sets audio format
  AudioConfig format(String format) {
    _config[LegacyExtensionKeys.audioFormat] = format;
    return this;
  }

  /// Sets audio quality
  AudioConfig quality(String quality) {
    _config[LegacyExtensionKeys.audioQuality] = quality;
    return this;
  }

  /// Sets sample rate
  AudioConfig sampleRate(int rate) {
    _config[LegacyExtensionKeys.sampleRate] = rate;
    return this;
  }

  /// Sets language code
  AudioConfig languageCode(String code) {
    _config[LegacyExtensionKeys.languageCode] = code;
    return this;
  }

  /// Sets voice for TTS
  AudioConfig voice(String voiceName) {
    _config[LegacyExtensionKeys.voice] = voiceName;
    return this;
  }

  /// Sets voice ID for ElevenLabs
  AudioConfig voiceId(String voiceId) {
    _config[LegacyExtensionKeys.voiceId] = voiceId;
    return this;
  }

  /// Sets stability parameter for ElevenLabs TTS
  AudioConfig stability(double stability) {
    _config[LegacyExtensionKeys.stability] = stability;
    return this;
  }

  /// Sets similarity boost parameter for ElevenLabs TTS
  AudioConfig similarityBoost(double similarityBoost) {
    _config[LegacyExtensionKeys.similarityBoost] = similarityBoost;
    return this;
  }

  /// Sets style parameter for ElevenLabs TTS
  AudioConfig style(double style) {
    _config[LegacyExtensionKeys.style] = style;
    return this;
  }

  /// Enables speaker boost for ElevenLabs TTS
  AudioConfig useSpeakerBoost(bool enable) {
    _config[LegacyExtensionKeys.useSpeakerBoost] = enable;
    return this;
  }

  /// Enables diarization for STT
  AudioConfig diarize(bool enabled) {
    _config[LegacyExtensionKeys.diarize] = enabled;
    return this;
  }

  /// Sets number of speakers for diarization
  AudioConfig numSpeakers(int count) {
    _config[LegacyExtensionKeys.numSpeakers] = count;
    return this;
  }

  /// Enables timestamp inclusion
  AudioConfig includeTimestamps(bool enabled) {
    _config[LegacyExtensionKeys.includeTimestamps] = enabled;
    return this;
  }

  /// Sets timestamp granularity
  AudioConfig timestampGranularity(String granularity) {
    _config[LegacyExtensionKeys.timestampGranularity] = granularity;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);
}
