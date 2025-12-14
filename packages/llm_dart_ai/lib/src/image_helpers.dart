// High-level image helpers that operate on ImageGenerationCapability instances.

library;

import 'package:llm_dart_core/llm_dart_core.dart';

/// High-level image generation helper using an existing [ImageGenerationCapability].
///
/// This mirrors the bundle-level `generateImage(...)` helper but does not
/// require a `"provider:model"` identifier or `LLMBuilder`.
Future<ImageGenerationResponse> generateImageWithModel(
  ImageGenerationCapability model, {
  required String prompt,
  String? modelId,
  String? negativePrompt,
  String? size,
  int? count,
  int? seed,
  int? steps,
  double? guidanceScale,
  bool? enhancePrompt,
  String? style,
  String? quality,
  String? responseFormat,
  String? user,
}) {
  final request = ImageGenerationRequest(
    prompt: prompt,
    model: modelId,
    negativePrompt: negativePrompt,
    size: size,
    count: count,
    seed: seed,
    steps: steps,
    guidanceScale: guidanceScale,
    enhancePrompt: enhancePrompt,
    style: style,
    quality: quality,
    responseFormat: responseFormat,
    user: user,
  );

  return model.generateImages(request);
}
