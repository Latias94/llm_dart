import 'dart:convert';

import 'package:llm_dart_transport/llm_dart_transport.dart' show Logger;

import '../../../../core/capability.dart';
import '../../../../models/image_models.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';
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

    final model = request.model ?? _config.model;

    if (_support.isImagenModel(model)) {
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
    return _executeMutation(
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

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    return _executeMutation(
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
        .where((image) => image.data != null)
        .map(
          (image) =>
              'data:image/${image.format ?? 'png'};base64,${base64Encode(image.data!)}',
        )
        .toList();
  }

  Future<ImageGenerationResponse> _executeMutation({
    required String prompt,
    required ImageInput image,
    required int? count,
    required String logLabel,
    required String missingDataErrorMessage,
    required String urlInputErrorMessage,
  }) async {
    final model = _config.model;
    final endpoint = 'models/$model:generateContent';

    final imageInput = _encodeInlineImage(
      image,
      urlInputErrorMessage: urlInputErrorMessage,
    );
    if (imageInput == null) {
      throw ArgumentError(missingDataErrorMessage);
    }

    final requestData = _support.buildGeminiInlineImageRequest(
      prompt: prompt,
      imageBase64: imageInput.base64,
      mimeType: imageInput.mimeType,
      config: _config,
      count: count,
    );

    try {
      final response = await _client.postJson(endpoint, requestData);
      return _support.parseGeminiResponse(response, model);
    } catch (e) {
      _logger.severe('$logLabel failed: $e');
      rethrow;
    }
  }

  _GoogleInlineImageInput? _encodeInlineImage(
    ImageInput image, {
    required String urlInputErrorMessage,
  }) {
    if (image.data != null) {
      return _GoogleInlineImageInput(
        base64: base64Encode(image.data!),
        mimeType: _support.mimeTypeFromFormat(image.format ?? 'png'),
      );
    }

    if (image.url != null) {
      throw UnsupportedError(urlInputErrorMessage);
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
