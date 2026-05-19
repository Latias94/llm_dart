import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_model_capabilities.dart';
import 'openai_image_request_validation.dart';
import 'openai_options.dart';

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

Map<String, Object?> buildOpenAIImageGenerationRequestBody({
  required String modelId,
  required ImageGenerationRequest request,
  required OpenAIImageOptions? options,
}) {
  return {
    'model': modelId,
    'prompt': request.prompt!,
    'n': request.count,
    if (request.size != null) 'size': request.size,
    if (options?.style case final style?) 'style': style.value,
    if (options?.quality case final quality?) 'quality': quality.value,
    if (options?.background case final background?)
      'background': background.value,
    if (options?.moderation case final moderation?)
      'moderation': moderation.value,
    if (options?.outputFormat case final outputFormat?)
      'output_format': outputFormat.value,
    if (options?.outputCompression case final outputCompression?)
      'output_compression': outputCompression,
    if (options?.user case final user?) 'user': user,
    if (shouldIncludeOpenAIImageResponseFormat(modelId))
      'response_format':
          (options?.responseFormat ?? OpenAIImageResponseFormat.base64Json)
              .value,
  };
}
