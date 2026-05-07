part of 'provider_compat.dart';

mixin OpenAIProviderImagesMixin implements ImageGenerationCapability {
  OpenAIImages get _images;

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    return _images.generateImages(request);
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    return _images.editImage(request);
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    return _images.createVariation(request);
  }

  @override
  List<String> getSupportedSizes() {
    return _images.getSupportedSizes();
  }

  @override
  List<String> getSupportedFormats() {
    return _images.getSupportedFormats();
  }

  @override
  bool get supportsImageEditing => _images.supportsImageEditing;

  @override
  bool get supportsImageVariations => _images.supportsImageVariations;

  @override
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
    return _images.generateImage(
      prompt: prompt,
      model: model,
      negativePrompt: negativePrompt,
      imageSize: imageSize,
      batchSize: batchSize,
      seed: seed,
      numInferenceSteps: numInferenceSteps,
      guidanceScale: guidanceScale,
      promptEnhancement: promptEnhancement,
    );
  }
}
