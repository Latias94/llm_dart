import 'package:llm_dart_core/llm_dart_core.dart';

/// Audio configuration builder for LLM providers.
///
/// 注意：这是一个遗留的配置构建器，仅用于与旧代码和测试兼容。
/// 新代码请优先使用 `LLMBuilder` 上的音频相关方法：
/// `audioFormat`, `audioQuality`, `sampleRate`, `languageCode` 等，
/// 这些方法会直接通过 [LLMConfigKeys] 写入统一的扩展配置。
@Deprecated(
  'AudioConfig is legacy. Use LLMBuilder audio helpers like '
  'audioFormat(), audioQuality(), sampleRate(), languageCode(), '
  'and related methods instead.',
)
class AudioConfig {
  final Map<String, dynamic> _config = {};

  /// Sets audio format
  AudioConfig format(String format) {
    _config[LLMConfigKeys.audioFormat] = format;
    return this;
  }

  /// Sets audio quality
  AudioConfig quality(String quality) {
    _config[LLMConfigKeys.audioQuality] = quality;
    return this;
  }

  /// Sets sample rate
  AudioConfig sampleRate(int rate) {
    _config[LLMConfigKeys.sampleRate] = rate;
    return this;
  }

  /// Sets language code
  AudioConfig languageCode(String code) {
    _config[LLMConfigKeys.languageCode] = code;
    return this;
  }

  /// Sets voice for TTS
  AudioConfig voice(String voiceName) {
    _config[LLMConfigKeys.voice] = voiceName;
    return this;
  }

  /// Sets voice ID for ElevenLabs
  AudioConfig voiceId(String voiceId) {
    _config[LLMConfigKeys.voiceId] = voiceId;
    return this;
  }

  /// Sets stability parameter for ElevenLabs TTS
  AudioConfig stability(double stability) {
    _config[LLMConfigKeys.stability] = stability;
    return this;
  }

  /// Sets similarity boost parameter for ElevenLabs TTS
  AudioConfig similarityBoost(double similarityBoost) {
    _config[LLMConfigKeys.similarityBoost] = similarityBoost;
    return this;
  }

  /// Sets style parameter for ElevenLabs TTS
  AudioConfig style(double style) {
    _config[LLMConfigKeys.style] = style;
    return this;
  }

  /// Enables speaker boost for ElevenLabs TTS
  AudioConfig useSpeakerBoost(bool enable) {
    _config[LLMConfigKeys.useSpeakerBoost] = enable;
    return this;
  }

  /// Enables diarization for STT
  AudioConfig diarize(bool enabled) {
    _config[LLMConfigKeys.diarize] = enabled;
    return this;
  }

  /// Sets number of speakers for diarization
  AudioConfig numSpeakers(int count) {
    _config[LLMConfigKeys.numSpeakers] = count;
    return this;
  }

  /// Enables timestamp inclusion
  AudioConfig includeTimestamps(bool enabled) {
    _config[LLMConfigKeys.includeTimestamps] = enabled;
    return this;
  }

  /// Sets timestamp granularity
  AudioConfig timestampGranularity(String granularity) {
    _config[LLMConfigKeys.timestampGranularity] = granularity;
    return this;
  }

  /// Get the configuration map
  Map<String, dynamic> build() => Map.from(_config);
}
