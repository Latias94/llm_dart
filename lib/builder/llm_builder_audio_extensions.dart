part of 'llm_builder.dart';

/// Audio and speech configuration helpers for [LLMBuilder].
extension LLMBuilderAudioExtensions on LLMBuilder {
  /// Audio configuration methods
  LLMBuilder audioFormat(String format) =>
      extension(LLMConfigKeys.audioFormat, format);

  LLMBuilder audioQuality(String quality) =>
      extension(LLMConfigKeys.audioQuality, quality);

  LLMBuilder sampleRate(int rate) =>
      extension(LLMConfigKeys.sampleRate, rate);

  LLMBuilder languageCode(String code) =>
      extension(LLMConfigKeys.languageCode, code);

  /// Advanced audio configuration methods
  LLMBuilder audioProcessingMode(String mode) =>
      extension(LLMConfigKeys.audioProcessingMode, mode);

  LLMBuilder includeTimestamps(bool enabled) =>
      extension(LLMConfigKeys.includeTimestamps, enabled);

  LLMBuilder timestampGranularity(String granularity) =>
      extension(LLMConfigKeys.timestampGranularity, granularity);

  LLMBuilder textNormalization(String mode) =>
      extension(LLMConfigKeys.textNormalization, mode);

  LLMBuilder instructions(String instructions) =>
      extension(LLMConfigKeys.instructions, instructions);

  LLMBuilder previousText(String text) =>
      extension(LLMConfigKeys.previousText, text);

  LLMBuilder nextText(String text) =>
      extension(LLMConfigKeys.nextText, text);

  LLMBuilder audioSeed(int seed) =>
      extension(LLMConfigKeys.audioSeed, seed);

  LLMBuilder enableLogging(bool enabled) =>
      extension(LLMConfigKeys.enableLogging, enabled);

  LLMBuilder optimizeStreamingLatency(int level) =>
      extension(LLMConfigKeys.optimizeStreamingLatency, level);

  /// STT-specific configuration methods
  LLMBuilder diarize(bool enabled) =>
      extension(LLMConfigKeys.diarize, enabled);

  LLMBuilder numSpeakers(int count) =>
      extension(LLMConfigKeys.numSpeakers, count);

  LLMBuilder tagAudioEvents(bool enabled) =>
      extension(LLMConfigKeys.tagAudioEvents, enabled);

  LLMBuilder webhook(bool enabled) =>
      extension(LLMConfigKeys.webhook, enabled);

  LLMBuilder prompt(String prompt) =>
      extension(LLMConfigKeys.prompt, prompt);

  LLMBuilder responseFormat(String format) =>
      extension(LLMConfigKeys.responseFormat, format);

  LLMBuilder cloudStorageUrl(String url) =>
      extension(LLMConfigKeys.cloudStorageUrl, url);
}

