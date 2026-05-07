part of 'google_image_support.dart';

final class _GoogleImageResponseSupport {
  static const _formatSupport = _GoogleImageFormatSupport();

  const _GoogleImageResponseSupport();

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
            final format = _formatSupport.extractFormatFromMimeType(mimeType);

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
}
