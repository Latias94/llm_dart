part of 'openai_image_support.dart';

final class _OpenAIImageResponseSupport {
  const _OpenAIImageResponseSupport();

  ImageGenerationResponse parseImageResponse(
    Map<String, dynamic> responseData, {
    required String? model,
    required String providerLabel,
  }) {
    final data = responseData['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid response format from $providerLabel: missing data field',
        responseData.toString(),
      );
    }

    try {
      final images = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid image item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        List<int>? imageData;
        if (item['b64_json'] != null) {
          try {
            imageData = base64Decode(item['b64_json'] as String);
          } catch (e) {
            throw ResponseFormatError(
              'Failed to decode base64 image data: $e',
              item['b64_json'].toString(),
            );
          }
        }

        return GeneratedImage(
          url: item['url'] as String?,
          data: imageData,
          revisedPrompt: item['revised_prompt'] as String?,
          format: 'png',
        );
      }).toList(growable: false);

      if (images.isEmpty) {
        throw ResponseFormatError(
          'No images returned from $providerLabel',
          'Empty data array',
        );
      }

      return ImageGenerationResponse(
        images: images,
        model: model,
        revisedPrompt: images.first.revisedPrompt,
        usage: null,
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse image response: $e',
        responseData.toString(),
      );
    }
  }
}
