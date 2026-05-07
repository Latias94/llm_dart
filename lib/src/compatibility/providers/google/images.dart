import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart' show Logger;

import '../../../../core/capability.dart';
import '../../../../models/image_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
import 'google_image_support.dart';

part 'google_images_generation_support.dart';
part 'google_images_mutation_support.dart';

/// Google Images capability implementation
///
/// Supports both Gemini 2.0 Flash Preview Image Generation and Imagen 3 models.
///
/// **Gemini Image Generation:**
/// - Uses conversational approach with responseModalities: ['TEXT', 'IMAGE']
/// - Supports text-to-image and image editing
/// - Model: gemini-2.0-flash-preview-image-generation
///
/// **Imagen 3:**
/// - Dedicated image generation model
/// - Higher quality, specialized for image generation
/// - Model: imagen-3.0-generate-002
///
/// Reference: https://ai.google.dev/gemini-api/docs/image-generation
class GoogleImages implements ImageGenerationCapability {
  final GoogleClient _client;
  final GoogleConfig _config;
  final Logger _logger = Logger('GoogleImages');
  final GoogleImageSupport _support = const GoogleImageSupport();
  static const _generationSupport = _GoogleImagesGenerationSupport();
  static const _mutationSupport = _GoogleImagesMutationSupport();

  GoogleImages(this._client, this._config);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    return _generationSupport.generateImages(
      client: _client,
      config: _config,
      logger: _logger,
      support: _support,
      request: request,
    );
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    return _mutationSupport.editImage(
      client: _client,
      config: _config,
      logger: _logger,
      support: _support,
      request: request,
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    return _mutationSupport.createVariation(
      client: _client,
      config: _config,
      logger: _logger,
      support: _support,
      request: request,
    );
  }

  @override
  List<String> getSupportedSizes() {
    return [
      '1:1',
      '3:4',
      '4:3',
      '9:16',
      '16:9',
    ];
  }

  @override
  List<String> getSupportedFormats() {
    return ['png', 'jpeg', 'webp'];
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
    return _generationSupport.generateImage(
      client: _client,
      config: _config,
      logger: _logger,
      support: _support,
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
