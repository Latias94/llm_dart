import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:http_parser/http_parser.dart';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'client.dart';
import 'config.dart';
import '../defaults.dart';

/// OpenAI Image Generation capability implementation
///
/// This module handles image generation functionality for OpenAI providers.
class OpenAIImages
    implements ImageGenerationCapability, ImageGenerationCallOptionsCapability {
  final OpenAIClient client;
  final OpenAIConfig config;

  OpenAIImages(this.client, this.config);

  Map<String, dynamic>? _providerOptionsBody(ProviderOptions providerOptions) {
    if (providerOptions.isEmpty) return null;
    return providerOptionsNamespace(
      providerOptions,
      config.providerId,
      fallbackProviderId: 'openai',
    );
  }

  Map<String, dynamic> _buildProviderMetadata(
    String endpoint, {
    required String model,
  }) {
    final payload = <String, dynamic>{
      'model': model,
      'endpoint': endpoint,
    };
    return {
      config.providerId: payload,
      '${config.providerId}.image': payload,
    };
  }

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) async {
    return generateImagesWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
    );
  }

  @override
  Future<ImageGenerationResponse> generateImagesWithCallOptions(
    ImageGenerationRequest request, {
    required LLMCallOptions callOptions,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final modelUsed = request.model ?? config.model;
    final warnings = <LLMWarning>[];
    if (request.aspectRatio != null && request.aspectRatio!.trim().isNotEmpty) {
      warnings.add(
        const LLMUnsupportedWarning(
          feature: 'aspectRatio',
          details:
              'OpenAI image APIs do not support `aspectRatio`. Use `size` or provider-specific parameters instead.',
        ),
      );
    }

    var requestBody = <String, dynamic>{
      'model': modelUsed,
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

    final providerOptionsBody = _providerOptionsBody(request.providerOptions);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      requestBody.addAll(providerOptionsBody);
    }

    requestBody = callOptions.mergeIntoRequestBody(requestBody);

    final responseData = await client.postJsonWithHeaders(
      'images/generations',
      requestBody,
      headers: callOptions.headers,
    );
    final json = responseData.json;

    final data = json['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid response format from OpenAI image generation API: missing data field',
        json.toString(),
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
        model: modelUsed,
        revisedPrompt: images.isNotEmpty ? images.first.revisedPrompt : null,
        usage: null, // OpenAI doesn't provide usage info for image generation
        warnings: warnings,
        responses: [
          ImageModelResponseMetadata(
            timestamp: startedAt,
            modelId: modelUsed,
            headers: responseData.headers.isEmpty ? null : responseData.headers,
          ),
        ],
        providerMetadata: _buildProviderMetadata(
          'images/generations',
          model: modelUsed,
        ),
      );
    } catch (e) {
      if (e is LLMError) rethrow;
      throw ResponseFormatError(
        'Failed to parse image generation response: $e',
        json.toString(),
      );
    }
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) async {
    return editImageWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
    );
  }

  @override
  Future<ImageGenerationResponse> editImageWithCallOptions(
    ImageEditRequest request, {
    required LLMCallOptions callOptions,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final modelUsed = request.model ?? config.model;
    final warnings = <LLMWarning>[];
    if (request.aspectRatio != null && request.aspectRatio!.trim().isNotEmpty) {
      warnings.add(
        const LLMUnsupportedWarning(
          feature: 'aspectRatio',
          details:
              'OpenAI image APIs do not support `aspectRatio`. Use `size` or provider-specific parameters instead.',
        ),
      );
    }

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

    final providerOptionsBody = _providerOptionsBody(request.providerOptions);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      formData.addAll(providerOptionsBody);
    }

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

    final response = await _postMultipartFormWithCallOptions(
      'images/edits',
      callOptions.mergeIntoRequestBody(formData),
      callOptions: callOptions,
    );
    return _parseImageResponse(
      response.json,
      request.model,
      startedAt: startedAt,
      responseHeaders: response.headers.isEmpty ? null : response.headers,
      warnings: warnings,
      providerMetadata: _buildProviderMetadata(
        'images/edits',
        model: modelUsed,
      ),
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
      ImageVariationRequest request) async {
    return createVariationWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
    );
  }

  @override
  Future<ImageGenerationResponse> createVariationWithCallOptions(
    ImageVariationRequest request, {
    required LLMCallOptions callOptions,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final modelUsed = request.model ?? config.model;
    final warnings = <LLMWarning>[];
    if (request.aspectRatio != null && request.aspectRatio!.trim().isNotEmpty) {
      warnings.add(
        const LLMUnsupportedWarning(
          feature: 'aspectRatio',
          details:
              'OpenAI image APIs do not support `aspectRatio`. Use `size` or provider-specific parameters instead.',
        ),
      );
    }

    // Prepare multipart form data for image variation
    final formData = <String, dynamic>{
      if (request.model != null) 'model': request.model,
      if (request.count != null) 'n': request.count,
      if (request.size != null) 'size': request.size,
      if (request.responseFormat != null)
        'response_format': request.responseFormat,
      if (request.user != null) 'user': request.user,
    };

    final providerOptionsBody = _providerOptionsBody(request.providerOptions);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      formData.addAll(providerOptionsBody);
    }

    // Add image data
    if (request.image.data != null) {
      formData['image'] = request.image.data!;
    } else {
      throw const InvalidRequestError(
        'Image data is required for image variation',
      );
    }

    final response = await _postMultipartFormWithCallOptions(
      'images/variations',
      callOptions.mergeIntoRequestBody(formData),
      callOptions: callOptions,
    );
    return _parseImageResponse(
      response.json,
      request.model,
      startedAt: startedAt,
      responseHeaders: response.headers.isEmpty ? null : response.headers,
      warnings: warnings,
      providerMetadata: _buildProviderMetadata(
        'images/variations',
        model: modelUsed,
      ),
    );
  }

  @override
  List<String> getSupportedSizes() {
    return openaiSupportedImageSizes;
  }

  @override
  List<String> getSupportedFormats() {
    return openaiSupportedImageFormats;
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
  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      _postMultipartForm(
    String endpoint,
    Map<String, dynamic> formData,
  ) async {
    return _postMultipartFormWithCallOptions(
      endpoint,
      formData,
      callOptions: const LLMCallOptions(),
    );
  }

  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      _postMultipartFormWithCallOptions(
    String endpoint,
    Map<String, dynamic> formData, {
    required LLMCallOptions callOptions,
  }) async {
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

    return await client.postFormWithResponseHeaders(
      endpoint,
      dioFormData,
      headers: callOptions.headers,
    );
  }

  /// Helper method to parse image generation response
  ImageGenerationResponse _parseImageResponse(
    Map<String, dynamic> responseData,
    String? model, {
    required DateTime startedAt,
    required Map<String, String>? responseHeaders,
    List<LLMWarning> warnings = const <LLMWarning>[],
    Map<String, dynamic>? providerMetadata,
  }) {
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
        warnings: warnings,
        responses: [
          ImageModelResponseMetadata(
            timestamp: startedAt,
            modelId: model ?? config.model,
            headers: responseHeaders,
          ),
        ],
        providerMetadata: providerMetadata,
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
