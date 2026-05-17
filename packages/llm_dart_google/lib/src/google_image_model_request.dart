import 'dart:convert';

import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_image_editing.dart';
import 'google_options.dart';

GoogleImageModelSettings resolveGoogleImageModelSettings(
  ProviderModelOptions settings,
) {
  return resolveProviderModelOptions<GoogleImageModelSettings>(
    settings,
    parameterName: 'settings',
    expectedTypeName: 'GoogleImageModelSettings',
    usageContext: 'Google image models',
  );
}

GoogleImageOptions? resolveGoogleImageProviderOptions(
  CallOptions callOptions,
) {
  return resolveProviderInvocationOptions<GoogleImageOptions>(
    callOptions.providerOptions,
    parameterName: 'request.callOptions.providerOptions',
    expectedTypeName: 'GoogleImageOptions',
    usageContext: 'Google image models',
  );
}

bool isGoogleGeminiImageModel(String modelId) {
  return modelId.toLowerCase().contains('gemini');
}

int resolveGoogleImageMaxImagesPerCall({
  required String modelId,
  required GoogleImageModelSettings settings,
}) {
  return settings.maxImagesPerCall ??
      (isGoogleGeminiImageModel(modelId) ? 1 : 4);
}

void validateGoogleImageGenerationRequest({
  required ImageGenerationRequest request,
  required GoogleImageOptions? options,
  required bool isGeminiImageModel,
  required int maxImagesPerCall,
  required GoogleImageModelSettings settings,
}) {
  if (request.size != null) {
    throw ArgumentError.value(
      request.size,
      'request.size',
      'Google image models do not support request.size. Use GoogleImageOptions.aspectRatio instead.',
    );
  }

  if (isGeminiImageModel && request.count != 1) {
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

  if (isGeminiImageModel && options?.personGeneration != null) {
    throw ArgumentError.value(
      options?.personGeneration,
      'request.callOptions.providerOptions.personGeneration',
      'GoogleImageOptions.personGeneration is only supported for Imagen image models.',
    );
  }

  final safetySettings = resolveGoogleImageSafetySettings(
    options: options,
    settings: settings,
  );
  if (!isGeminiImageModel && safetySettings.isNotEmpty) {
    throw ArgumentError.value(
      safetySettings,
      'request.callOptions.providerOptions.safetySettings',
      'Google safety settings are only supported for Gemini image models. Imagen safety filters are not configurable through this surface.',
    );
  }
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

Map<String, Object?> buildGoogleImageGenerationRequestBody({
  required ImageGenerationRequest request,
  required GoogleImageOptions? options,
  required bool isGeminiImageModel,
  required GoogleImageModelSettings settings,
}) {
  return isGeminiImageModel
      ? buildGoogleGeminiImageRequestBody(
          request,
          options: options,
          settings: settings,
        )
      : buildGoogleImagenRequestBody(
          request,
          options: options,
        );
}

Map<String, Object?> buildGoogleImagenRequestBody(
  ImageGenerationRequest request, {
  required GoogleImageOptions? options,
}) {
  return {
    'instances': [
      {
        'prompt': request.prompt,
      },
    ],
    'parameters': {
      'sampleCount': request.count,
      if (options?.aspectRatio case final aspectRatio?)
        'aspectRatio': aspectRatio.value,
      if (options?.personGeneration case final personGeneration?)
        'personGeneration': personGeneration.value,
    },
  };
}

Map<String, Object?> buildGoogleGeminiImageRequestBody(
  ImageGenerationRequest request, {
  required GoogleImageOptions? options,
  required GoogleImageModelSettings settings,
}) {
  final safetySettings = resolveGoogleImageSafetySettings(
    options: options,
    settings: settings,
  );
  return buildGoogleGeminiImageBody(
    prompt: request.prompt,
    imageParts: const [],
    options: options,
    safetySettings: safetySettings,
  );
}

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
  );
}

Map<String, Object?> buildGoogleGeminiImageBody({
  required String prompt,
  required List<Map<String, Object?>> imageParts,
  required GoogleImageOptions? options,
  required List<GoogleSafetySetting> safetySettings,
}) {
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
      if (options?.aspectRatio case final aspectRatio?)
        'imageConfig': {
          'aspectRatio': aspectRatio.value,
        },
    },
    if (safetySettings.isNotEmpty)
      'safetySettings': [
        for (final setting in safetySettings) setting.toJson(),
      ],
  };
}

Map<String, Object?> encodeGoogleImageEditInput(GoogleImageEditInput input) {
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

List<GoogleSafetySetting> resolveGoogleImageSafetySettings({
  required GoogleImageOptions? options,
  required GoogleImageModelSettings settings,
}) {
  return options?.safetySettings ?? settings.safetySettings;
}
