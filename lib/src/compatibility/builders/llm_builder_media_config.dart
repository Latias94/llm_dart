import '../../../builder/llm_builder.dart';

/// Legacy media convenience methods layered on top of [LLMBuilder].
extension LLMBuilderMediaConfig on LLMBuilder {
  /// Image generation configuration methods.
  LLMBuilder imageSize(String size) => extension('imageSize', size);
  LLMBuilder batchSize(int size) => extension('batchSize', size);
  LLMBuilder imageSeed(String seed) => extension('imageSeed', seed);
  LLMBuilder numInferenceSteps(int steps) =>
      extension('numInferenceSteps', steps);
  LLMBuilder guidanceScale(double scale) => extension('guidanceScale', scale);
  LLMBuilder promptEnhancement(bool enabled) =>
      extension('promptEnhancement', enabled);

  /// Audio configuration methods.
  LLMBuilder audioFormat(String format) => extension('audioFormat', format);
  LLMBuilder audioQuality(String quality) => extension('audioQuality', quality);
  LLMBuilder sampleRate(int rate) => extension('sampleRate', rate);
  LLMBuilder languageCode(String code) => extension('languageCode', code);

  /// Advanced audio configuration methods.
  LLMBuilder audioProcessingMode(String mode) =>
      extension('audioProcessingMode', mode);
  LLMBuilder includeTimestamps(bool enabled) =>
      extension('includeTimestamps', enabled);
  LLMBuilder timestampGranularity(String granularity) =>
      extension('timestampGranularity', granularity);
  LLMBuilder textNormalization(String mode) =>
      extension('textNormalization', mode);
  LLMBuilder instructions(String instructions) =>
      extension('instructions', instructions);
  LLMBuilder previousText(String text) => extension('previousText', text);
  LLMBuilder nextText(String text) => extension('nextText', text);
  LLMBuilder audioSeed(int seed) => extension('audioSeed', seed);
  LLMBuilder enableLogging(bool enabled) => extension('enableLogging', enabled);
  LLMBuilder optimizeStreamingLatency(int level) =>
      extension('optimizeStreamingLatency', level);

  /// STT-specific configuration methods.
  LLMBuilder diarize(bool enabled) => extension('diarize', enabled);
  LLMBuilder numSpeakers(int count) => extension('numSpeakers', count);
  LLMBuilder tagAudioEvents(bool enabled) =>
      extension('tagAudioEvents', enabled);
  LLMBuilder webhook(bool enabled) => extension('webhook', enabled);
  LLMBuilder prompt(String prompt) => extension('prompt', prompt);
  LLMBuilder responseFormat(String format) =>
      extension('responseFormat', format);
  LLMBuilder sourceUrl(String url) => extension('sourceUrl', url);

  @Deprecated('Use sourceUrl instead.')
  LLMBuilder cloudStorageUrl(String url) => sourceUrl(url);
}
