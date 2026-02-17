import 'dart:convert';

import 'package:dio/dio.dart' hide CancelToken;
import 'package:llm_dart_core/llm_dart_core.dart';

import '../defaults.dart';
import 'client.dart';
import 'openai_request_config.dart';

/// OpenAI-style Image Generation capability implementation.
///
/// This module targets OpenAI-compatible endpoints:
/// - `POST /images/generations`
/// - `POST /images/edits`
/// - `POST /images/variations`
class OpenAIStyleImages
    implements ImageGenerationCapability, ImageGenerationCallOptionsCapability {
  final OpenAIClient client;
  final OpenAIRequestConfig config;

  OpenAIStyleImages(this.client, this.config);

  Map<String, dynamic>? _providerOptionsBody(ProviderOptions providerOptions) {
    if (providerOptions.isEmpty) return null;

    final providerId =
        config.providerId.trim().isEmpty ? 'openai' : config.providerId.trim();

    return providerOptionsNamespace(
      providerOptions,
      providerId,
      fallbackProviderId: providerId == 'openai-compatible' ? 'openai' : null,
    );
  }

  Map<String, dynamic> _buildProviderMetadata(
    String endpoint, {
    String? model,
  }) {
    final providerId =
        config.providerId.trim().isEmpty ? 'openai' : config.providerId.trim();
    final payload = <String, dynamic>{
      if (model != null) 'model': model,
      'endpoint': endpoint,
    };
    return {
      providerId: payload,
      '$providerId.image': payload,
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
    final warnings = <LLMWarning>[];
    if (request.aspectRatio != null && request.aspectRatio!.trim().isNotEmpty) {
      warnings.add(
        const LLMUnsupportedWarning(
          feature: 'aspectRatio',
          details:
              'OpenAI-style image APIs do not support `aspectRatio`. Use `size` or provider-specific parameters instead.',
        ),
      );
    }

    var requestBody = <String, dynamic>{
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
          format: 'png',
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
        usage: null,
        warnings: warnings,
        responses: [
          ImageModelResponseMetadata(
            timestamp: startedAt,
            modelId: request.model ?? config.model,
            headers: responseData.headers.isEmpty ? null : responseData.headers,
          ),
        ],
        providerMetadata: _buildProviderMetadata(
          'images/generations',
          model: request.model ?? config.model,
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
    final warnings = <LLMWarning>[];
    if (request.aspectRatio != null && request.aspectRatio!.trim().isNotEmpty) {
      warnings.add(
        const LLMUnsupportedWarning(
          feature: 'aspectRatio',
          details:
              'OpenAI-style image APIs do not support `aspectRatio`. Use `size` or provider-specific parameters instead.',
        ),
      );
    }

    final formData = <String, dynamic>{
      'prompt': request.prompt,
      if (request.model != null) 'model': request.model,
      if (request.count != null) 'n': request.count,
      if (request.size != null) 'size': request.size,
      if (request.responseFormat != null)
        'response_format': request.responseFormat,
      if (request.user != null) 'user': request.user,
    };

    if (request.image.data != null) {
      formData['image'] = request.image.data!;
    } else {
      throw const InvalidRequestError(
        'Image data is required for image editing',
      );
    }

    if (request.mask != null) {
      if (request.mask!.data != null) {
        formData['mask'] = request.mask!.data!;
      }
    }

    final providerOptionsBody = _providerOptionsBody(request.providerOptions);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      formData.addAll(providerOptionsBody);
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
        model: request.model ?? config.model,
      ),
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
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
    final warnings = <LLMWarning>[];
    if (request.aspectRatio != null && request.aspectRatio!.trim().isNotEmpty) {
      warnings.add(
        const LLMUnsupportedWarning(
          feature: 'aspectRatio',
          details:
              'OpenAI-style image APIs do not support `aspectRatio`. Use `size` or provider-specific parameters instead.',
        ),
      );
    }

    final formData = <String, dynamic>{
      if (request.model != null) 'model': request.model,
      if (request.count != null) 'n': request.count,
      if (request.size != null) 'size': request.size,
      if (request.responseFormat != null)
        'response_format': request.responseFormat,
      if (request.user != null) 'user': request.user,
    };

    if (request.image.data != null) {
      formData['image'] = request.image.data!;
    } else {
      throw const InvalidRequestError(
        'Image data is required for image variation',
      );
    }

    final providerOptionsBody = _providerOptionsBody(request.providerOptions);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      formData.addAll(providerOptionsBody);
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
        model: request.model ?? config.model,
      ),
    );
  }

  @override
  List<String> getSupportedSizes() {
    return openaiStyleSupportedImageSizes;
  }

  @override
  List<String> getSupportedFormats() {
    return openaiStyleSupportedImageFormats;
  }

  @override
  bool get supportsImageEditing => true;

  @override
  bool get supportsImageVariations => true;

  Future<({Map<String, dynamic> json, Map<String, String> headers})>
      _postMultipartFormWithCallOptions(
    String endpoint,
    Map<String, dynamic> formData, {
    required LLMCallOptions callOptions,
  }) async {
    final dioFormData = FormData();

    for (final entry in formData.entries) {
      if (entry.value is List<int>) {
        final bytes = entry.value as List<int>;
        dioFormData.files.add(
          MapEntry(
            entry.key,
            MultipartFile.fromBytes(
              bytes,
              filename: '${entry.key}.png',
            ),
          ),
        );
      } else {
        dioFormData.fields.add(MapEntry(entry.key, entry.value.toString()));
      }
    }

    return await client.postFormWithResponseHeaders(
      endpoint,
      dioFormData,
      headers: callOptions.headers,
    );
  }

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
          format: 'png',
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
        usage: null,
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
