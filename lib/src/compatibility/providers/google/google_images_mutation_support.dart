part of 'images.dart';

final class _GoogleImagesMutationSupport {
  const _GoogleImagesMutationSupport();

  Future<ImageGenerationResponse> editImage({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageEditRequest request,
  }) async {
    final model = config.model;
    final endpoint = 'models/$model:generateContent';

    final imageInput = _encodeInlineImage(
      request.image,
      support,
      urlInputErrorMessage:
          'Google image editing does not support URL inputs, only direct image data',
    );
    if (imageInput == null) {
      throw ArgumentError('Image data is required for Google image editing');
    }

    final requestData = support.buildGeminiInlineImageRequest(
      prompt: request.prompt,
      imageBase64: imageInput.base64,
      mimeType: imageInput.mimeType,
      config: config,
      count: request.count,
    );

    try {
      final response = await client.postJson(endpoint, requestData);
      return support.parseGeminiResponse(response, model);
    } catch (e) {
      logger.severe('Google image editing failed: $e');
      rethrow;
    }
  }

  Future<ImageGenerationResponse> createVariation({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageVariationRequest request,
  }) async {
    final model = config.model;
    final endpoint = 'models/$model:generateContent';

    final imageInput = _encodeInlineImage(
      request.image,
      support,
      urlInputErrorMessage:
          'Google image variations do not support URL inputs, only direct image data',
    );
    if (imageInput == null) {
      throw ArgumentError('Image data is required for Google image variations');
    }

    final requestData = support.buildGeminiInlineImageRequest(
      prompt: GoogleImageSupport.variationPrompt,
      imageBase64: imageInput.base64,
      mimeType: imageInput.mimeType,
      config: config,
      count: request.count,
    );

    try {
      final response = await client.postJson(endpoint, requestData);
      return support.parseGeminiResponse(response, model);
    } catch (e) {
      logger.severe('Google image variation failed: $e');
      rethrow;
    }
  }

  _GoogleInlineImageInput? _encodeInlineImage(
    ImageInput image,
    GoogleImageSupport support, {
    required String urlInputErrorMessage,
  }) {
    if (image.data != null) {
      return _GoogleInlineImageInput(
        base64: base64Encode(image.data!),
        mimeType: support.mimeTypeFromFormat(image.format ?? 'png'),
      );
    }

    if (image.url != null) {
      throw UnsupportedError(
        urlInputErrorMessage,
      );
    }

    return null;
  }
}

final class _GoogleInlineImageInput {
  final String base64;
  final String mimeType;

  const _GoogleInlineImageInput({
    required this.base64,
    required this.mimeType,
  });
}
