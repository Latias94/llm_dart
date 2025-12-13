part of 'llm_builder.dart';

/// Image generation configuration helpers for [LLMBuilder].
extension LLMBuilderImageExtensions on LLMBuilder {
  /// Image generation configuration methods
  LLMBuilder imageSize(String size) =>
      extension(LLMConfigKeys.imageSize, size);

  LLMBuilder batchSize(int size) =>
      extension(LLMConfigKeys.batchSize, size);

  LLMBuilder imageSeed(String seed) =>
      extension(LLMConfigKeys.imageSeed, seed);

  LLMBuilder numInferenceSteps(int steps) =>
      extension(LLMConfigKeys.numInferenceSteps, steps);

  LLMBuilder guidanceScale(double scale) =>
      extension(LLMConfigKeys.guidanceScale, scale);

  LLMBuilder promptEnhancement(bool enabled) =>
      extension(LLMConfigKeys.promptEnhancement, enabled);
}

