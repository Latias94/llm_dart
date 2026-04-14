import 'dart:convert';

import '../../../../models/image_models.dart';
import '../../../../providers/google/config.dart';

/// Provider-local request and response shaping for Google image compatibility.
final class GoogleImageSupport {
  const GoogleImageSupport();

  static const String variationPrompt =
      'Create variations of this image with similar style and content but different details';

  bool isImagenModel(String model) {
    return model.contains('imagen');
  }

  Map<String, dynamic> buildImagenRequest(
    ImageGenerationRequest request,
  ) {
    return {
      'instances': [
        {
          'prompt': request.prompt,
        }
      ],
      'parameters': {
        if (request.count != null) 'sampleCount': request.count,
        if (request.size != null)
          'aspectRatio': convertSizeToAspectRatio(request.size!),
        'personGeneration': 'allow_adult',
      },
    };
  }

  Map<String, dynamic> buildGeminiRequest(
    ImageGenerationRequest request,
    GoogleConfig config,
  ) {
    final imageConfig = <String, dynamic>{
      if (request.size != null) 'aspectRatio': request.size!,
    };

    return {
      'contents': [
        {
          'parts': [
            {'text': request.prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': config.responseModalities ?? ['TEXT', 'IMAGE'],
        'imageConfig': imageConfig,
        if (request.count != null) 'candidateCount': request.count,
        if (config.maxTokens != null) 'maxOutputTokens': config.maxTokens,
        if (config.temperature != null) 'temperature': config.temperature,
        if (config.topP != null) 'topP': config.topP,
        if (config.topK != null) 'topK': config.topK,
        if (config.stopSequences != null) 'stopSequences': config.stopSequences,
      },
      if (config.safetySettings != null)
        'safetySettings':
            config.safetySettings!.map((setting) => setting.toJson()).toList(),
    };
  }

  Map<String, dynamic> buildGeminiInlineImageRequest({
    required String prompt,
    required String imageBase64,
    required String mimeType,
    required GoogleConfig config,
    int? count,
  }) {
    return {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': imageBase64,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
        if (count != null) 'candidateCount': count,
        if (config.temperature != null) 'temperature': config.temperature,
      },
      if (config.safetySettings != null)
        'safetySettings':
            config.safetySettings!.map((setting) => setting.toJson()).toList(),
    };
  }

  ImageGenerationResponse parseImagenResponse(
    Map<String, dynamic> response,
    String model,
  ) {
    final predictions = response['predictions'] as List? ?? [];
    final images = <GeneratedImage>[];

    for (final prediction in predictions) {
      final predictionMap = prediction as Map<String, dynamic>;
      final imageData = predictionMap['bytesBase64Encoded'] as String?;

      if (imageData != null) {
        final bytes = base64Decode(imageData);
        images.add(GeneratedImage(
          data: bytes,
          format: 'png',
        ));
      }
    }

    return ImageGenerationResponse(
      images: images,
      model: model,
    );
  }

  ImageGenerationResponse parseGeminiResponse(
    Map<String, dynamic> response,
    String model,
  ) {
    final candidates = response['candidates'] as List? ?? [];
    final images = <GeneratedImage>[];
    String? revisedPrompt;

    for (final candidate in candidates) {
      final candidateMap = candidate as Map<String, dynamic>;
      final content = candidateMap['content'] as Map<String, dynamic>? ?? {};
      final parts = content['parts'] as List? ?? [];

      for (final part in parts) {
        final partMap = part as Map<String, dynamic>;

        if (partMap['text'] != null && revisedPrompt == null) {
          revisedPrompt = partMap['text'] as String;
        }

        final inlineData = partMap['inlineData'] as Map<String, dynamic>?;
        if (inlineData != null) {
          final mimeType = inlineData['mimeType'] as String?;
          final data = inlineData['data'] as String?;

          if (data != null) {
            final bytes = base64Decode(data);
            final format = extractFormatFromMimeType(mimeType);

            images.add(GeneratedImage(
              data: bytes,
              format: format,
              revisedPrompt: revisedPrompt,
            ));
          }
        }
      }
    }

    return ImageGenerationResponse(
      images: images,
      model: model,
      revisedPrompt: revisedPrompt,
    );
  }

  String convertSizeToAspectRatio(String size) {
    switch (size.toLowerCase()) {
      case '256x256':
      case '512x512':
      case '1024x1024':
        return '1:1';
      case '768x1344':
      case '1024x1792':
        return '3:4';
      case '1344x768':
      case '1792x1024':
        return '4:3';
      case '640x1536':
        return '9:16';
      case '1536x640':
        return '16:9';
      default:
        final parts = size.split('x');
        if (parts.length == 2) {
          final width = int.tryParse(parts[0]);
          final height = int.tryParse(parts[1]);
          if (width != null && height != null) {
            if (width == height) return '1:1';
            if (width > height) {
              final ratio = width / height;
              if (ratio > 1.7) return '16:9';
              return '4:3';
            } else {
              final ratio = height / width;
              if (ratio > 1.7) return '9:16';
              return '3:4';
            }
          }
        }
        return '1:1';
    }
  }

  String extractFormatFromMimeType(String? mimeType) {
    if (mimeType == null) return 'png';

    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
      return 'jpeg';
    } else if (mimeType.contains('webp')) {
      return 'webp';
    } else {
      return 'png';
    }
  }

  String mimeTypeFromFormat(String format) {
    switch (format.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'png':
      default:
        return 'image/png';
    }
  }
}
