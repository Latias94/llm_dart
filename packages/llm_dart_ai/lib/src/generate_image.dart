import 'package:llm_dart_core/llm_dart_core.dart';

import 'types.dart';

/// Generate images using a provider-agnostic capability.
Future<GenerateImageResult> generateImage({
  required ImageGenerationCapability model,
  required ImageGenerationRequest request,
  CancelToken? cancelToken,
}) async {
  final response = await model.generateImages(request);
  return GenerateImageResult(rawResponse: response);
}

/// Convenience helper to generate images from a plain prompt.
@Deprecated(
  'Use generateImage(model: ..., request: ImageGenerationRequest(...)) instead.',
)
Future<GenerateImageResult> generateImageFromPrompt({
  required ImageGenerationCapability model,
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
  CancelToken? cancelToken,
}) {
  return generateImage(
    model: model,
    request: ImageGenerationRequest(
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
    ),
    cancelToken: cancelToken,
  );
}
