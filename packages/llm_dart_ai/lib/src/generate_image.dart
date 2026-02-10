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
