part of 'images.dart';

final class _GoogleImagesMutationRequestSupport {
  const _GoogleImagesMutationRequestSupport();

  Future<ImageGenerationResponse> editImage({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageEditRequest request,
  }) async {
    return _executeMutation(
      client: client,
      config: config,
      logger: logger,
      support: support,
      prompt: request.prompt,
      image: request.image,
      count: request.count,
      logLabel: 'Google image editing',
      missingDataErrorMessage:
          'Image data is required for Google image editing',
      urlInputErrorMessage:
          'Google image editing does not support URL inputs, only direct image data',
    );
  }

  Future<ImageGenerationResponse> createVariation({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageVariationRequest request,
  }) async {
    return _executeMutation(
      client: client,
      config: config,
      logger: logger,
      support: support,
      prompt: GoogleImageSupport.variationPrompt,
      image: request.image,
      count: request.count,
      logLabel: 'Google image variation',
      missingDataErrorMessage:
          'Image data is required for Google image variations',
      urlInputErrorMessage:
          'Google image variations do not support URL inputs, only direct image data',
    );
  }

  Future<ImageGenerationResponse> _executeMutation({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required String prompt,
    required ImageInput image,
    required int? count,
    required String logLabel,
    required String missingDataErrorMessage,
    required String urlInputErrorMessage,
  }) async {
    final model = config.model;
    final endpoint = 'models/$model:generateContent';
    const inlineImageSupport = _GoogleImagesInlineImageSupport();

    final imageInput = inlineImageSupport.encode(
      image,
      support,
      urlInputErrorMessage: urlInputErrorMessage,
    );
    if (imageInput == null) {
      throw ArgumentError(missingDataErrorMessage);
    }

    final requestData = support.buildGeminiInlineImageRequest(
      prompt: prompt,
      imageBase64: imageInput.base64,
      mimeType: imageInput.mimeType,
      config: config,
      count: count,
    );

    try {
      final response = await client.postJson(endpoint, requestData);
      return support.parseGeminiResponse(response, model);
    } catch (e) {
      logger.severe('$logLabel failed: $e');
      rethrow;
    }
  }
}
