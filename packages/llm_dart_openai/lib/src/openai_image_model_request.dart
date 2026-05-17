import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_image_editing.dart';
import 'openai_non_text_model_support.dart';
import 'openai_options.dart';

OpenAIImageModelSettings resolveOpenAIImageModelSettings(
  ProviderModelOptions settings,
) {
  return resolveOpenAIModelSettings<OpenAIImageModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'OpenAIImageModelSettings for OpenAI-family image models',
  );
}

OpenAIImageOptions? resolveOpenAIImageProviderOptions(
  CallOptions callOptions,
) {
  return resolveOpenAIProviderOptions<OpenAIImageOptions>(
    callOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'OpenAIImageOptions for OpenAI-family image models',
  );
}

int resolveOpenAIImageMaxImagesPerCall(String modelId) {
  return switch (modelId) {
    'dall-e-2' => 10,
    'dall-e-3' => 1,
    'chatgpt-image-latest' => 10,
    'gpt-image-1' => 10,
    'gpt-image-1-mini' => 10,
    'gpt-image-1.5' => 10,
    'gpt-image-2' => 10,
    _ => 1,
  };
}

bool shouldIncludeOpenAIImageResponseFormat(String modelId) {
  return !hasDefaultOpenAIImageResponseFormat(modelId);
}

bool hasDefaultOpenAIImageResponseFormat(String modelId) {
  const defaultResponseFormatPrefixes = [
    'chatgpt-image-',
    'gpt-image-1-mini',
    'gpt-image-1.5',
    'gpt-image-1',
    'gpt-image-2',
  ];

  return defaultResponseFormatPrefixes.any(modelId.startsWith);
}

void validateOpenAIImageGenerationRequest({
  required String modelId,
  required ImageGenerationRequest request,
  required OpenAIImageOptions? options,
  required int maxImagesPerCall,
}) {
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

  if (options?.outputCompression case final outputCompression?) {
    validateOpenAIImageOutputCompression(
      outputCompression,
      'request.callOptions.providerOptions.outputCompression',
    );
  }
}

void validateOpenAIImageEditRequest(
  OpenAIImageEditRequest request,
  OpenAIImageOptions? options,
) {
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

Map<String, Object?> buildOpenAIImageGenerationRequestBody({
  required String modelId,
  required ImageGenerationRequest request,
  required OpenAIImageOptions? options,
}) {
  return {
    'model': modelId,
    'prompt': request.prompt,
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

TransportMultipartBody buildOpenAIImageEditRequestBody({
  required String modelId,
  required OpenAIImageEditRequest request,
  required OpenAIImageOptions? options,
}) {
  final outputCompression =
      request.outputCompression ?? options?.outputCompression;
  return buildTransportMultipartBody(
    fields: [
      TransportMultipartField.text(
        name: 'model',
        value: modelId,
      ),
      TransportMultipartField.text(
        name: 'prompt',
        value: request.prompt,
      ),
      for (final image in request.images)
        TransportMultipartField.file(
          name: 'image',
          filename: image.filename ?? buildOpenAIImageFilename(image.mediaType),
          mediaType: image.mediaType,
          bytes: image.bytes,
        ),
      if (request.mask case final mask?)
        TransportMultipartField.file(
          name: 'mask',
          filename: mask.filename ?? 'mask.png',
          mediaType: mask.mediaType,
          bytes: mask.bytes,
        ),
      TransportMultipartField.text(
        name: 'n',
        value: request.count.toString(),
      ),
      if (request.size case final size?)
        TransportMultipartField.text(
          name: 'size',
          value: size,
        ),
      if (options?.background case final background?)
        TransportMultipartField.text(
          name: 'background',
          value: background.value,
        ),
      if (request.inputFidelity case final inputFidelity?)
        TransportMultipartField.text(
          name: 'input_fidelity',
          value: inputFidelity.value,
        ),
      if (request.partialImages case final partialImages?)
        TransportMultipartField.text(
          name: 'partial_images',
          value: partialImages.toString(),
        ),
      if (options?.quality case final quality?)
        TransportMultipartField.text(
          name: 'quality',
          value: quality.value,
        ),
      if (outputCompression != null)
        TransportMultipartField.text(
          name: 'output_compression',
          value: outputCompression.toString(),
        ),
      if (options?.outputFormat case final outputFormat?)
        TransportMultipartField.text(
          name: 'output_format',
          value: outputFormat.value,
        ),
      if (options?.responseFormat case final responseFormat?)
        TransportMultipartField.text(
          name: 'response_format',
          value: responseFormat.value,
        ),
      if (options?.user case final user?)
        TransportMultipartField.text(
          name: 'user',
          value: user,
        ),
    ],
  );
}

void validateOpenAIImageEditInput(
  OpenAIImageEditInput input,
  String parameterName,
) {
  if (input.bytes.isEmpty) {
    throw ArgumentError.value(
      input.bytes,
      '$parameterName.bytes',
      'OpenAI image editing inputs must provide non-empty bytes.',
    );
  }

  if (!input.mediaType.startsWith('image/')) {
    throw ArgumentError.value(
      input.mediaType,
      '$parameterName.mediaType',
      'OpenAI image editing inputs must use an image/* media type.',
    );
  }
}

void validateOpenAIImageOutputCompression(
  int outputCompression,
  String parameterName,
) {
  if (outputCompression < 0 || outputCompression > 100) {
    throw ArgumentError.value(
      outputCompression,
      parameterName,
      'OpenAI image outputCompression must be between 0 and 100.',
    );
  }
}

String buildOpenAIImageFilename(String mediaType) {
  final normalized = mediaType.split(';').first.trim().toLowerCase();
  final extension = switch (normalized) {
    'image/png' => 'png',
    'image/jpeg' => 'jpeg',
    'image/jpg' => 'jpg',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'bin',
  };

  return 'image.$extension';
}
