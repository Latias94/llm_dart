import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_image_editing.dart';
import 'google_image_options.dart';

GoogleImageEditRequest buildGoogleImageEditRequestFromCommon({
  required ImageGenerationRequest request,
  required bool isGeminiImageModel,
}) {
  validateGoogleImageEditSupport(isGeminiImageModel: isGeminiImageModel);

  if (request.mask != null) {
    throw UnsupportedError(
      'Google image editing through ImageGenerationRequest does not support mask inputs yet.',
    );
  }

  final prompt = request.prompt;
  if (prompt == null || prompt.trim().isEmpty) {
    throw ArgumentError.value(
      prompt,
      'request.prompt',
      'Google image editing through ImageGenerationRequest requires a non-empty prompt.',
    );
  }

  return GoogleImageEditRequest(
    prompt: prompt,
    images: [
      for (final file in request.files) _toGoogleImageEditInput(file),
    ],
    count: request.count,
    aspectRatio: request.aspectRatio,
    seed: request.seed,
    callOptions: request.callOptions,
  );
}

GoogleImageEditRequest buildGoogleImageEditRequestFromVariation(
  GoogleImageVariationRequest request,
) {
  return GoogleImageEditRequest(
    prompt: request.prompt,
    images: request.images,
    count: request.count,
    aspectRatio: request.aspectRatio,
    seed: request.seed,
    callOptions: request.callOptions,
  );
}

void validateGoogleImageEditSupport({
  required bool isGeminiImageModel,
}) {
  if (!isGeminiImageModel) {
    throw UnsupportedError(
      'Google image editing currently requires Gemini image models. Imagen models remain generation-only on this provider-owned helper surface.',
    );
  }
}

void validateGoogleImageEditRequest(
  GoogleImageEditRequest request,
  GoogleImageOptions? options,
) {
  if (request.images.isEmpty) {
    throw ArgumentError.value(
      request.images,
      'request.images',
      'Google image editing requires at least one image input.',
    );
  }

  if (request.count != 1) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'Gemini image editing currently supports only count=1.',
    );
  }

  if (options?.personGeneration != null) {
    throw ArgumentError.value(
      options?.personGeneration,
      'request.callOptions.providerOptions.personGeneration',
      'GoogleImageOptions.personGeneration is only supported for Imagen image generation, not Gemini image editing.',
    );
  }

  for (var index = 0; index < request.images.length; index += 1) {
    final image = request.images[index];
    if (!image.mediaType.startsWith('image/')) {
      throw ArgumentError.value(
        image.mediaType,
        'request.images[$index].mediaType',
        'Google image editing inputs must use an image/* media type.',
      );
    }

    if ((image.bytes == null) == (image.uri == null)) {
      throw ArgumentError.value(
        image,
        'request.images[$index]',
        'Google image editing inputs must provide either bytes or a URI.',
      );
    }
  }
}

GoogleImageEditInput _toGoogleImageEditInput(ImageGenerationInput input) {
  final uri = input.uri;
  if (uri != null) {
    return GoogleImageEditInput.uri(
      uri,
      mediaType: input.mediaType,
      filename: input.filename,
    );
  }

  final bytes = input.bytes;
  if (bytes == null) {
    throw ArgumentError.value(
      input,
      'request.files',
      'Google image editing inputs must provide bytes or a URI.',
    );
  }

  return GoogleImageEditInput.bytes(
    bytes,
    mediaType: input.mediaType,
    filename: input.filename,
  );
}
