import '../../../builder/llm_builder.dart';

/// Legacy image convenience methods layered on top of [LLMBuilder].
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
}
