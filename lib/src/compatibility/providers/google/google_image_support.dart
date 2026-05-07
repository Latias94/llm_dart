import 'dart:convert';

import '../../../../models/image_models.dart';
import '../../../../providers/google/config.dart';

part 'google_image_format_support.dart';
part 'google_image_model_support.dart';
part 'google_image_request_support.dart';
part 'google_image_response_support.dart';

/// Provider-local request and response shaping for Google image compatibility.
final class GoogleImageSupport {
  static const String variationPrompt =
      'Create variations of this image with similar style and content but different details';

  static const _modelSupport = _GoogleImageModelSupport();
  static const _requestSupport = _GoogleImageRequestSupport();
  static const _responseSupport = _GoogleImageResponseSupport();
  static const _formatSupport = _GoogleImageFormatSupport();

  const GoogleImageSupport();

  bool isImagenModel(String model) {
    return _modelSupport.isImagenModel(model);
  }

  Map<String, dynamic> buildImagenRequest(
    ImageGenerationRequest request,
  ) {
    return _requestSupport.buildImagenRequest(request);
  }

  Map<String, dynamic> buildGeminiRequest(
    ImageGenerationRequest request,
    GoogleConfig config,
  ) {
    return _requestSupport.buildGeminiRequest(request, config);
  }

  Map<String, dynamic> buildGeminiInlineImageRequest({
    required String prompt,
    required String imageBase64,
    required String mimeType,
    required GoogleConfig config,
    int? count,
  }) {
    return _requestSupport.buildGeminiInlineImageRequest(
      prompt: prompt,
      imageBase64: imageBase64,
      mimeType: mimeType,
      config: config,
      count: count,
    );
  }

  ImageGenerationResponse parseImagenResponse(
    Map<String, dynamic> response,
    String model,
  ) {
    return _responseSupport.parseImagenResponse(response, model);
  }

  ImageGenerationResponse parseGeminiResponse(
    Map<String, dynamic> response,
    String model,
  ) {
    return _responseSupport.parseGeminiResponse(response, model);
  }

  String convertSizeToAspectRatio(String size) {
    return _formatSupport.convertSizeToAspectRatio(size);
  }

  String extractFormatFromMimeType(String? mimeType) {
    return _formatSupport.extractFormatFromMimeType(mimeType);
  }

  String mimeTypeFromFormat(String format) {
    return _formatSupport.mimeTypeFromFormat(format);
  }
}
