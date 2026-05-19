import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_image_options.dart';
import 'google_image_safety_settings.dart';
import 'google_model_settings.dart';

void validateGoogleImagenImageGenerationRequest({
  required ImageGenerationRequest request,
  required GoogleImageOptions? options,
  required int maxImagesPerCall,
  required GoogleImageModelSettings settings,
}) {
  if (request.count > maxImagesPerCall) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'Google image models currently support at most $maxImagesPerCall generated images per call.',
    );
  }

  if (request.seed != null) {
    throw ArgumentError.value(
      request.seed,
      'request.seed',
      'Google Imagen image models do not support request.seed through this provider.',
    );
  }

  final safetySettings = resolveGoogleImageSafetySettings(
    options: options,
    settings: settings,
  );
  if (safetySettings.isNotEmpty) {
    throw ArgumentError.value(
      safetySettings,
      'request.callOptions.providerOptions.safetySettings',
      'Google safety settings are only supported for Gemini image models. Imagen safety filters are not configurable through this surface.',
    );
  }
}

Map<String, Object?> buildGoogleImagenRequestBody(
  ImageGenerationRequest request, {
  required GoogleImageOptions? options,
}) {
  final aspectRatio = request.aspectRatio ?? options?.aspectRatio?.value;
  return {
    'instances': [
      {
        'prompt': request.prompt,
      },
    ],
    'parameters': {
      'sampleCount': request.count,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
      if (options?.personGeneration case final personGeneration?)
        'personGeneration': personGeneration.value,
    },
  };
}
