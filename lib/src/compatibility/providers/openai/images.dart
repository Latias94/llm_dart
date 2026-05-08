import '../../../../core/capability.dart';
import '../../../../models/image_models.dart';
import 'client.dart';
import '../../../../providers/openai/config.dart';
import 'openai_image_support.dart';

/// OpenAI Image Generation capability implementation
///
/// This module handles image generation functionality for OpenAI providers.
class OpenAIImages implements ImageGenerationCapability {
  static const List<String> _supportedSizes = [
    '256x256',
    '512x512',
    '1024x1024',
    '1792x1024',
    '1024x1792',
  ];
  static const List<String> _supportedFormats = ['url', 'b64_json'];

  final OpenAIClient client;
  final OpenAIConfig config;
  final OpenAIImageSupport _support = const OpenAIImageSupport();

  OpenAIImages(this.client, this.config);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    final requestBody = _support.buildGenerationRequest(
      request,
      config: config,
    );

    final responseData =
        await client.postJson('images/generations', requestBody);
    return _support.parseImageResponse(
      responseData,
      model: request.model ?? config.model,
      providerLabel: 'OpenAI image generation API',
    );
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    final responseData = await client.postForm(
      'images/edits',
      _support.buildEditFormData(request),
    );
    return _support.parseImageResponse(
      responseData,
      model: request.model ?? config.model,
      providerLabel: 'OpenAI image API',
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) async {
    final responseData = await client.postForm(
      'images/variations',
      _support.buildVariationFormData(request),
    );
    return _support.parseImageResponse(
      responseData,
      model: request.model ?? config.model,
      providerLabel: 'OpenAI image API',
    );
  }

  @override
  List<String> getSupportedSizes() {
    return _supportedSizes;
  }

  @override
  List<String> getSupportedFormats() {
    return _supportedFormats;
  }

  @override
  bool get supportsImageEditing => true;

  @override
  bool get supportsImageVariations => true;

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
