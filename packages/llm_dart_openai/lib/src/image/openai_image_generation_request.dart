import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_options.dart';
import 'openai_image_request_validation.dart';

void validateOpenAIImageGenerationRequest({
  required String modelId,
  required ImageGenerationRequest request,
  required OpenAIImageOptions? options,
  required int maxImagesPerCall,
}) {
  if (request.prompt == null || request.prompt!.trim().isEmpty) {
    throw ArgumentError.value(
      request.prompt,
      'request.prompt',
      'OpenAI image generation requires a non-empty prompt.',
    );
  }

  if (request.count < 1) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'OpenAI image generation requires count >= 1.',
    );
  }

  if (request.count > maxImagesPerCall) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'OpenAI image model $modelId supports at most $maxImagesPerCall generated images per call.',
    );
  }

  if (request.aspectRatio != null) {
    throw ArgumentError.value(
      request.aspectRatio,
      'request.aspectRatio',
      'OpenAI image models do not support request.aspectRatio. Use request.size instead.',
    );
  }

  if (request.seed != null) {
    throw ArgumentError.value(
      request.seed,
      'request.seed',
      'OpenAI image models do not support request.seed.',
    );
  }

  if (options?.outputCompression case final outputCompression?) {
    validateOpenAIImageOutputCompression(
      outputCompression,
      'request.callOptions.providerOptions.outputCompression',
    );
  }
}
