import 'package:llm_dart_core/llm_dart_core.dart';

import 'ai_errors.dart';
import 'types.dart';

/// Generate images using a provider-agnostic capability.
Future<GenerateImageResult> generateImage({
  required ImageGenerationCapability model,
  required ImageGenerationRequest request,
  LLMCallOptions defaultCallOptions = const LLMCallOptions(),
  LLMCallOptions callOptions = const LLMCallOptions(),
  CancelToken? cancelToken,
}) async {
  final ImageGenerationResponse response;

  final effectiveCallOptions = defaultCallOptions.mergedWith(callOptions);

  if (effectiveCallOptions.isEmpty) {
    response = await model.generateImages(request);
  } else {
    if (model is! ImageGenerationCallOptionsCapability) {
      throw const InvalidRequestError(
        'This model does not support call-level overrides (headers/body) for image generation. '
        'Implement `ImageGenerationCallOptionsCapability` (or use a provider that does).',
      );
    }

    response = await (model as ImageGenerationCallOptionsCapability)
        .generateImagesWithCallOptions(
      request,
      callOptions: effectiveCallOptions,
    );
  }

  if (response.images.isEmpty) {
    throw NoImageGeneratedError(response: response);
  }

  return GenerateImageResult(rawResponse: response);
}
