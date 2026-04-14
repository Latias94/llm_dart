import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../models/image_models.dart';
import '../../../../providers/openai/config.dart';

/// Provider-local request and response shaping for OpenAI image compatibility.
final class OpenAIImageSupport {
  const OpenAIImageSupport();

  Map<String, dynamic> buildGenerationRequest(
    ImageGenerationRequest request, {
    required OpenAIConfig config,
  }) {
    return {
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
  }

  FormData buildEditFormData(ImageEditRequest request) {
    if (request.image.data == null) {
      throw const InvalidRequestError(
        'Image data is required for image editing',
      );
    }

    final formData = FormData();
    formData.fields.add(MapEntry('prompt', request.prompt));
    if (request.model != null) {
      formData.fields.add(MapEntry('model', request.model!));
    }
    if (request.count != null) {
      formData.fields.add(MapEntry('n', request.count.toString()));
    }
    if (request.size != null) {
      formData.fields.add(MapEntry('size', request.size!));
    }
    if (request.responseFormat != null) {
      formData.fields.add(MapEntry('response_format', request.responseFormat!));
    }
    if (request.user != null) {
      formData.fields.add(MapEntry('user', request.user!));
    }

    formData.files.add(
      MapEntry(
        'image',
        MultipartFile.fromBytes(
          request.image.data!,
          filename: 'image.png',
          contentType: DioMediaType('image', 'png'),
        ),
      ),
    );

    if (request.mask?.data != null) {
      formData.files.add(
        MapEntry(
          'mask',
          MultipartFile.fromBytes(
            request.mask!.data!,
            filename: 'mask.png',
            contentType: DioMediaType('image', 'png'),
          ),
        ),
      );
    }

    return formData;
  }

  FormData buildVariationFormData(ImageVariationRequest request) {
    if (request.image.data == null) {
      throw const InvalidRequestError(
        'Image data is required for image variation',
      );
    }

    final formData = FormData();
    if (request.model != null) {
      formData.fields.add(MapEntry('model', request.model!));
    }
    if (request.count != null) {
      formData.fields.add(MapEntry('n', request.count.toString()));
    }
    if (request.size != null) {
      formData.fields.add(MapEntry('size', request.size!));
    }
    if (request.responseFormat != null) {
      formData.fields.add(MapEntry('response_format', request.responseFormat!));
    }
    if (request.user != null) {
      formData.fields.add(MapEntry('user', request.user!));
    }

    formData.files.add(
      MapEntry(
        'image',
        MultipartFile.fromBytes(
          request.image.data!,
          filename: 'image.png',
          contentType: DioMediaType('image', 'png'),
        ),
      ),
    );

    return formData;
  }

  ImageGenerationResponse parseImageResponse(
    Map<String, dynamic> responseData, {
    required String? model,
    required String providerLabel,
  }) {
    final data = responseData['data'] as List?;
    if (data == null) {
      throw ResponseFormatError(
        'Invalid response format from $providerLabel: missing data field',
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

        List<int>? imageData;
        if (item['b64_json'] != null) {
          try {
            imageData = base64Decode(item['b64_json'] as String);
          } catch (e) {
            throw ResponseFormatError(
              'Failed to decode base64 image data: $e',
              item['b64_json'].toString(),
            );
          }
        }

        return GeneratedImage(
          url: item['url'] as String?,
          data: imageData,
          revisedPrompt: item['revised_prompt'] as String?,
          format: 'png',
        );
      }).toList(growable: false);

      if (images.isEmpty) {
        throw ResponseFormatError(
          'No images returned from $providerLabel',
          'Empty data array',
        );
      }

      return ImageGenerationResponse(
        images: images,
        model: model,
        revisedPrompt: images.first.revisedPrompt,
        usage: null,
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
