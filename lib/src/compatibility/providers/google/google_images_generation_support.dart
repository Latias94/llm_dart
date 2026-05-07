part of 'images.dart';

final class _GoogleImagesGenerationSupport {
  const _GoogleImagesGenerationSupport();

  Future<ImageGenerationResponse> generateImages({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required ImageGenerationRequest request,
  }) async {
    logger.info('Generating images with prompt: ${request.prompt}');

    final model = request.model ?? config.model;

    if (support.isImagenModel(model)) {
      final endpoint = 'models/$model:predict';
      final requestData = support.buildImagenRequest(request);

      try {
        final response = await client.postJson(endpoint, requestData);
        return support.parseImagenResponse(response, model);
      } catch (e) {
        logger.severe('Imagen generation failed: $e');
        rethrow;
      }
    }

    final endpoint = 'models/$model:generateContent';
    final requestData = support.buildGeminiRequest(request, config);

    try {
      final response = await client.postJson(endpoint, requestData);
      return support.parseGeminiResponse(response, model);
    } catch (e) {
      logger.severe('Gemini generation failed: $e');
      rethrow;
    }
  }

  Future<List<String>> generateImage({
    required GoogleClient client,
    required GoogleConfig config,
    required Logger logger,
    required GoogleImageSupport support,
    required String prompt,
    String? model,
    String? negativePrompt,
    String? imageSize,
    int? batchSize,
    String? seed,
    int? numInferenceSteps,
    double? guidanceScale,
    bool? promptEnhancement,
  }) async {
    final response = await generateImages(
      client: client,
      config: config,
      logger: logger,
      support: support,
      request: ImageGenerationRequest(
        prompt: prompt,
        model: model,
        negativePrompt: negativePrompt,
        size: imageSize,
        count: batchSize,
        seed: seed != null ? int.tryParse(seed) : null,
        steps: numInferenceSteps,
        guidanceScale: guidanceScale,
        enhancePrompt: promptEnhancement,
      ),
    );

    return response.images
        .where((img) => img.data != null)
        .map((img) =>
            'data:image/${img.format ?? 'png'};base64,${base64Encode(img.data!)}')
        .toList();
  }
}
