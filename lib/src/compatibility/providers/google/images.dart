import 'dart:convert';
import 'package:llm_dart_transport/llm_dart_transport.dart' show Logger;

import '../../../../core/capability.dart';
import '../../../../models/image_models.dart';
import 'client.dart';
import '../../../../providers/google/config.dart';
import 'google_image_support.dart';

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

  GoogleImages(this._client, this._config);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    _logger.info('Generating images with prompt: ${request.prompt}');

    // Determine which API to use based on model
    if (_support.isImagenModel(request.model ?? _config.model)) {
      return _generateWithImagen(request);
    } else {
      return _generateWithGemini(request);
    }
  }

  /// Generate images using Imagen 3 API
  Future<ImageGenerationResponse> _generateWithImagen(
    ImageGenerationRequest request,
  ) async {
    final model = request.model ?? _config.model;
    final endpoint = 'models/$model:predict';
    final requestData = _support.buildImagenRequest(request);

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _support.parseImagenResponse(response, model);
    } catch (e) {
      _logger.severe('Imagen generation failed: $e');
      rethrow;
    }
  }

  /// Generate images using Gemini 2.0 Flash Preview Image Generation
  Future<ImageGenerationResponse> _generateWithGemini(
    ImageGenerationRequest request,
  ) async {
    final model = request.model ?? _config.model;
    final endpoint = 'models/$model:generateContent';
    final requestData = _support.buildGeminiRequest(request, _config);

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _support.parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('Gemini generation failed: $e');
      rethrow;
    }
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    // Google supports image editing through Gemini conversational approach
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    // Convert image to base64 for inline data
    String? imageBase64;
    String? mimeType;

    if (request.image.data != null) {
      imageBase64 = base64Encode(request.image.data!);
      mimeType = _support.mimeTypeFromFormat(request.image.format ?? 'png');
    } else if (request.image.url != null) {
      throw UnsupportedError(
          'Google image editing does not support URL inputs, only direct image data');
    }

    if (imageBase64 == null) {
      throw ArgumentError('Image data is required for Google image editing');
    }

    final requestData = _support.buildGeminiInlineImageRequest(
      prompt: request.prompt,
      imageBase64: imageBase64,
      mimeType: mimeType!,
      config: _config,
      count: request.count,
    );

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _support.parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('Google image editing failed: $e');
      rethrow;
    }
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    // Google doesn't have a direct variation API, but we can simulate it
    // by asking Gemini to create variations of the provided image
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    // Convert image to base64 for inline data
    String? imageBase64;
    String? mimeType;

    if (request.image.data != null) {
      imageBase64 = base64Encode(request.image.data!);
      mimeType = _support.mimeTypeFromFormat(request.image.format ?? 'png');
    } else if (request.image.url != null) {
      throw UnsupportedError(
          'Google image variations do not support URL inputs, only direct image data');
    }

    if (imageBase64 == null) {
      throw ArgumentError('Image data is required for Google image variations');
    }

    final requestData = _support.buildGeminiInlineImageRequest(
      prompt: GoogleImageSupport.variationPrompt,
      imageBase64: imageBase64,
      mimeType: mimeType!,
      config: _config,
      count: request.count,
    );

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _support.parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('Google image variation failed: $e');
      rethrow;
    }
  }

  @override
  List<String> getSupportedSizes() {
    // Google Imagen 3 supports these aspect ratios
    return [
      '1:1', // Square
      '3:4', // Portrait fullscreen
      '4:3', // Fullscreen
      '9:16', // Portrait
      '16:9', // Widescreen
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

    // For Google, we return base64 data URLs since images are returned as data
    return response.images
        .where((img) => img.data != null)
        .map((img) =>
            'data:image/${img.format ?? 'png'};base64,${base64Encode(img.data!)}')
        .toList();
  }
}
