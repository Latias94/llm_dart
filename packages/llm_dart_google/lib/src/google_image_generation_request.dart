import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_gemini_image_request.dart';
import 'google_image_options.dart';
import 'google_imagen_image_request.dart';
import 'google_model_settings.dart';

void validateGoogleImageGenerationRequest({
  required ImageGenerationRequest request,
  required GoogleImageOptions? options,
  required bool isGeminiImageModel,
  required int maxImagesPerCall,
  required GoogleImageModelSettings settings,
}) {
  if (request.prompt == null || request.prompt!.trim().isEmpty) {
    throw ArgumentError.value(
      request.prompt,
      'request.prompt',
      'Google image generation requires a non-empty prompt.',
    );
  }

  if (request.files.isNotEmpty || request.mask != null) {
    throw ArgumentError.value(
      request.files.isNotEmpty ? request.files : request.mask,
      request.files.isNotEmpty ? 'request.files' : 'request.mask',
      'Google image generation only supports shared request files and masks through Gemini image editing.',
    );
  }

  if (request.size != null) {
    throw ArgumentError.value(
      request.size,
      'request.size',
      'Google image models do not support request.size. Use GoogleImageOptions.aspectRatio instead.',
    );
  }

  if (isGeminiImageModel) {
    validateGoogleGeminiImageGenerationRequest(
      request: request,
      options: options,
      maxImagesPerCall: maxImagesPerCall,
    );
    return;
  }

  validateGoogleImagenImageGenerationRequest(
    request: request,
    options: options,
    maxImagesPerCall: maxImagesPerCall,
    settings: settings,
  );
}

Map<String, Object?> buildGoogleImageGenerationRequestBody({
  required ImageGenerationRequest request,
  required GoogleImageOptions? options,
  required bool isGeminiImageModel,
  required GoogleImageModelSettings settings,
}) {
  return isGeminiImageModel
      ? buildGoogleGeminiImageGenerationRequestBody(
          request,
          options: options,
          settings: settings,
        )
      : buildGoogleImagenRequestBody(
          request,
          options: options,
        );
}
