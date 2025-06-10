import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/capability.dart';
import '../../core/llm_error.dart';
import '../../core/provider_defaults.dart';
import '../../models/image_models.dart';
import 'client.dart';
import 'config.dart';

/// OpenAI Image Generation capability implementation
///
/// This module handles image generation functionality for OpenAI providers.
class OpenAIImages implements ImageGenerationCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIImages(this.client, this.config);

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    final requestBody = <String, dynamic>{
      'model': request.model ?? config.model,
      'prompt': request.prompt,
      if (request.negativePrompt != null)
        'negative_prompt': request.negativePrompt,
      if (request.size != null) 'size': request.size,
      if (request.count != null) 'n': request.count,
      if (request.seed != null) 'seed': request.seed,
      if (request.steps != null) 'num_inference_steps': request.steps,
      if (request.guidanceScale != null)
        'guidance_scale': request.guidanceScale,
      if (request.enhancePrompt != null)
        'prompt_enhancement': request.enhancePrompt,
      if (request.style != null) 'style': request.style,
      if (request.quality != null) 'quality': request.quality,
    };

    final responseData =
        await client.postJson('images/generations', requestBody);

    final data = responseData['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid response format from OpenAI image generation API: missing data field',
        responseData.toString(),
      );
    }

    // Extract images from response
    try {
      final images = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid image item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        final itemMap = item;
        List<int>? imageData;

        // Safely decode base64 data if present
        if (itemMap['b64_json'] != null) {
          try {
            final b64String = itemMap['b64_json'] as String;
            imageData = base64Decode(b64String);
          } catch (e) {
            throw ResponseFormatError(
              'Failed to decode base64 image data: $e',
              itemMap['b64_json'].toString(),
            );
          }
        }

        return GeneratedImage(
          url: itemMap['url'] as String?,
          data: imageData,
          revisedPrompt: itemMap['revised_prompt'] as String?,
          format: 'png', // OpenAI DALL-E generates PNG images
        );
      }).toList();

      if (images.isEmpty) {
        throw const ResponseFormatError(
          'No images returned from OpenAI image generation API',
          'Empty data array',
        );
      }

      return ImageGenerationResponse(
        images: images,
        model: request.model ?? config.model,
        revisedPrompt: images.isNotEmpty ? images.first.revisedPrompt : null,
        usage: null, // OpenAI doesn't provide usage info for image generation
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse image generation response: $e',
        responseData.toString(),
      );
    }
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    // Prepare multipart form data for image editing
    final formData = <String, dynamic>{
      'prompt': request.prompt,
      if (request.model != null) 'model': request.model,
      if (request.count != null) 'n': request.count,
      if (request.size != null) 'size': request.size,
      if (request.responseFormat != null)
        'response_format': request.responseFormat,
      if (request.user != null) 'user': request.user,
    };

    // Add image data
    if (request.image.data != null) {
      formData['image'] = request.image.data!;
    } else {
      throw const InvalidRequestError(
        'Image data is required for image editing',
      );
    }

    // Add mask data if provided
    if (request.mask != null) {
      if (request.mask!.data != null) {
        formData['mask'] = request.mask!.data!;
      }
      // Note: filePath support removed for Web platform compatibility
    }

    final responseData = await _postMultipartForm('images/edits', formData);
    return _parseImageResponse(responseData, request.model);
  }

  @override
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) async {
    // Prepare multipart form data for image variation
    final formData = <String, dynamic>{
      if (request.model != null) 'model': request.model,
      if (request.count != null) 'n': request.count,
      if (request.size != null) 'size': request.size,
      if (request.responseFormat != null)
        'response_format': request.responseFormat,
      if (request.user != null) 'user': request.user,
    };

    // Add image data
    if (request.image.data != null) {
      formData['image'] = request.image.data!;
    } else {
      throw const InvalidRequestError(
        'Image data is required for image variation',
      );
    }

    final responseData =
        await _postMultipartForm('images/variations', formData);
    return _parseImageResponse(responseData, request.model);
  }

  @override
  List<String> getSupportedSizes() {
    return ProviderDefaults.openaiSupportedImageSizes;
  }

  @override
  List<String> getSupportedFormats() {
    return ProviderDefaults.openaiSupportedImageFormats;
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

  /// Helper method to handle multipart form requests
  Future<Map<String, dynamic>> _postMultipartForm(
    String endpoint,
    Map<String, dynamic> formData,
  ) async {
    // Convert form data to Dio FormData
    final dioFormData = FormData();

    for (final entry in formData.entries) {
      if (entry.value is List<int>) {
        // Handle image/mask data
        final bytes = entry.value as List<int>;
        dioFormData.files.add(MapEntry(
          entry.key,
          MultipartFile.fromBytes(
            bytes,
            filename: '${entry.key}.png',
            contentType: MediaType('image', 'png'),
          ),
        ));
      } else {
        // Handle regular form fields
        dioFormData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
    }

    return await client.postForm(endpoint, dioFormData);
  }

  /// Helper method to parse image generation response
  ImageGenerationResponse _parseImageResponse(
    Map<String, dynamic> responseData,
    String? model,
  ) {
    final data = responseData['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid response format from OpenAI image API: missing data field',
        responseData.toString(),
      );
    }

    // Extract images from response
    try {
      final images = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw ResponseFormatError(
            'Invalid image item format: expected Map<String, dynamic>',
            item.toString(),
          );
        }

        final itemMap = item;
        List<int>? imageData;

        // Safely decode base64 data if present
        if (itemMap['b64_json'] != null) {
          try {
            final b64String = itemMap['b64_json'] as String;
            imageData = base64Decode(b64String);
          } catch (e) {
            throw ResponseFormatError(
              'Failed to decode base64 image data: $e',
              itemMap['b64_json'].toString(),
            );
          }
        }

        return GeneratedImage(
          url: itemMap['url'] as String?,
          data: imageData,
          revisedPrompt: itemMap['revised_prompt'] as String?,
          format: 'png', // OpenAI DALL-E generates PNG images
        );
      }).toList();

      if (images.isEmpty) {
        throw const ResponseFormatError(
          'No images returned from OpenAI image API',
          'Empty data array',
        );
      }

      return ImageGenerationResponse(
        images: images,
        model: model ?? config.model,
        revisedPrompt: images.isNotEmpty ? images.first.revisedPrompt : null,
        usage: null, // OpenAI doesn't provide usage info for image generation
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse image response: $e',
        responseData.toString(),
      );
    }
  }
}
