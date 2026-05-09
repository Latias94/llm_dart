import '../models/image_models.dart';

/// Capability interface for image generation
abstract class ImageGenerationCapability {
  /// Generate images from text prompts
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  );

  /// Edit an existing image based on a prompt
  Future<ImageGenerationResponse> editImage(
    ImageEditRequest request,
  );

  /// Create variations of an existing image
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  );

  /// Get supported image sizes for this provider
  List<String> getSupportedSizes();

  /// Get supported response formats for this provider
  List<String> getSupportedFormats();

  /// Check if the provider supports image editing
  bool get supportsImageEditing => true;

  /// Check if the provider supports image variations
  bool get supportsImageVariations => true;

  /// Simple image generation (convenience method)
  Future<List<String>> generateImage({
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
      ImageGenerationRequest(
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
        .map((img) => img.url)
        .where((url) => url != null)
        .cast<String>()
        .toList();
  }
}
