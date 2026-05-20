import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_gemini_image_request.dart';
import 'google_image_editing.dart';
import 'google_image_options.dart';
import 'google_image_safety_settings.dart';
import 'google_model_settings.dart';

Map<String, Object?> buildGoogleGeminiImageEditRequestBody(
  GoogleImageEditRequest request, {
  required GoogleImageOptions? options,
  required GoogleImageModelSettings settings,
}) {
  final safetySettings = resolveGoogleImageSafetySettings(
    options: options,
    settings: settings,
  );
  return buildGoogleGeminiImageBody(
    prompt: request.prompt,
    imageParts: [
      for (final image in request.images) encodeGoogleImageEditInput(image),
    ],
    options: options,
    safetySettings: safetySettings,
    aspectRatio: request.aspectRatio,
    seed: request.seed,
  );
}

Map<String, Object?> encodeGoogleImageEditInput(ImageGenerationInput input) {
  if (input.bytes case final bytes?) {
    return {
      'inlineData': {
        'mimeType': input.mediaType,
        'data': base64Encode(bytes),
      },
    };
  }

  return {
    'fileData': {
      'mimeType': input.mediaType,
      'fileUri': input.uri.toString(),
    },
  };
}
