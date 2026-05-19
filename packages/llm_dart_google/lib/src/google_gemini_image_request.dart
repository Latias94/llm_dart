import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_image_safety_settings.dart';
import 'google_options.dart';

void validateGoogleGeminiImageGenerationRequest({
  required ImageGenerationRequest request,
  required GoogleImageOptions? options,
  required int maxImagesPerCall,
}) {
  if (request.count != 1) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'Gemini image models currently support only count=1. Use an Imagen model for multi-image generation.',
    );
  }

  if (request.count > maxImagesPerCall) {
    throw ArgumentError.value(
      request.count,
      'request.count',
      'Google image models currently support at most $maxImagesPerCall generated images per call.',
    );
  }

  if (options?.personGeneration != null) {
    throw ArgumentError.value(
      options?.personGeneration,
      'request.callOptions.providerOptions.personGeneration',
      'GoogleImageOptions.personGeneration is only supported for Imagen image models.',
    );
  }
}

Map<String, Object?> buildGoogleGeminiImageGenerationRequestBody(
  ImageGenerationRequest request, {
  required GoogleImageOptions? options,
  required GoogleImageModelSettings settings,
}) {
  final safetySettings = resolveGoogleImageSafetySettings(
    options: options,
    settings: settings,
  );
  return buildGoogleGeminiImageBody(
    prompt: request.prompt!,
    imageParts: const [],
    options: options,
    safetySettings: safetySettings,
    aspectRatio: request.aspectRatio,
    seed: request.seed,
  );
}

Map<String, Object?> buildGoogleGeminiImageBody({
  required String prompt,
  required List<Map<String, Object?>> imageParts,
  required GoogleImageOptions? options,
  required List<GoogleSafetySetting> safetySettings,
  String? aspectRatio,
  int? seed,
}) {
  final resolvedAspectRatio = aspectRatio ?? options?.aspectRatio?.value;
  return {
    'contents': [
      {
        'parts': [
          {
            'text': prompt,
          },
          ...imageParts,
        ],
      },
    ],
    'generationConfig': {
      'responseModalities': [
        GoogleResponseModality.text.value,
        GoogleResponseModality.image.value,
      ],
      if (resolvedAspectRatio != null)
        'imageConfig': {
          'aspectRatio': resolvedAspectRatio,
        },
      if (seed != null) 'seed': seed,
    },
    if (safetySettings.isNotEmpty)
      'safetySettings': [
        for (final setting in safetySettings) setting.toJson(),
      ],
  };
}
