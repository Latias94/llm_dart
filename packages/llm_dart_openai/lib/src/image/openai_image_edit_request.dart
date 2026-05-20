import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'openai_image_editing.dart';
import 'openai_image_options.dart';
import 'openai_image_request_validation.dart';

OpenAIImageEditRequest buildOpenAIImageEditRequestFromCommon(
  ImageGenerationRequest request,
) {
  final prompt = request.prompt;
  if (prompt == null || prompt.trim().isEmpty) {
    throw ArgumentError.value(
      prompt,
      'request.prompt',
      'OpenAI image editing through ImageGenerationRequest requires a non-empty prompt.',
    );
  }

  if (request.aspectRatio != null) {
    throw ArgumentError.value(
      request.aspectRatio,
      'request.aspectRatio',
      'OpenAI image editing does not support request.aspectRatio. Use request.size instead.',
    );
  }

  if (request.seed != null) {
    throw ArgumentError.value(
      request.seed,
      'request.seed',
      'OpenAI image editing does not support request.seed.',
    );
  }

  return OpenAIImageEditRequest(
    prompt: prompt,
    images: [
      for (final file in request.files)
        _toOpenAIImageEditInput(file, 'request.files'),
    ],
    mask: request.mask == null
        ? null
        : _toOpenAIImageEditInput(request.mask!, 'request.mask'),
    count: request.count,
    size: request.size,
    callOptions: request.callOptions,
  );
}

void validateOpenAIImageEditRequest(
  OpenAIImageEditRequest request,
  OpenAIImageOptions? options, {
  required String modelId,
  required int maxImagesPerCall,
}) {
  if (request.prompt.trim().isEmpty) {
    throw ArgumentError.value(
      request.prompt,
      'request.prompt',
      'OpenAI image editing requires a non-empty prompt.',
    );
  }

  if (request.images.isEmpty) {
    throw ArgumentError.value(
      request.images,
      'request.images',
      'OpenAI image editing requires at least one image input.',
    );
  }

  if (request.count < 1) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'OpenAI image editing requires count >= 1.',
    );
  }

  if (request.count > maxImagesPerCall) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'OpenAI image model $modelId supports at most $maxImagesPerCall generated images per call.',
    );
  }

  if (request.partialImages case final partialImages? when partialImages < 1) {
    throw ArgumentError.value(
      partialImages,
      'request.partialImages',
      'OpenAI image editing partialImages must be >= 1.',
    );
  }

  if (request.outputCompression case final outputCompression?) {
    validateOpenAIImageOutputCompression(
      outputCompression,
      'request.outputCompression',
    );
  }

  if (options?.style != null) {
    throw ArgumentError.value(
      options?.style,
      'request.callOptions.providerOptions.style',
      'OpenAIImageOptions.style is only supported for image generation, not image editing.',
    );
  }

  if (options?.moderation != null) {
    throw ArgumentError.value(
      options?.moderation,
      'request.callOptions.providerOptions.moderation',
      'OpenAIImageOptions.moderation is only supported for image generation, not image editing.',
    );
  }

  if (options?.outputCompression case final outputCompression?) {
    validateOpenAIImageOutputCompression(
      outputCompression,
      'request.callOptions.providerOptions.outputCompression',
    );
  }

  for (var index = 0; index < request.images.length; index += 1) {
    validateOpenAIImageEditInput(
      request.images[index],
      'request.images[$index]',
    );
  }

  if (request.mask case final mask?) {
    validateOpenAIImageEditInput(
      mask,
      'request.mask',
    );
  }
}

OpenAIImageEditInput _toOpenAIImageEditInput(
  ImageGenerationInput input,
  String parameterName,
) {
  if (input.uri != null) {
    throw ArgumentError.value(
      input.uri,
      '$parameterName.uri',
      'OpenAI image editing does not support URL-backed common image inputs.',
    );
  }

  final bytes = input.bytes;
  if (bytes == null) {
    throw ArgumentError.value(
      input,
      parameterName,
      'OpenAI image editing inputs must provide image bytes.',
    );
  }

  return OpenAIImageEditInput(
    bytes: bytes,
    mediaType: input.mediaType,
    filename: input.filename,
  );
}
