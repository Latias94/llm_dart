import 'dart:convert';

import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_openai_compatible/client.dart';

import 'config.dart';

class XAIImages
    implements
        ImageGenerationCapability,
        ImageGenerationCallOptionsCapability,
        ImageGenerationMaxImagesPerCallCapability {
  final OpenAIClient client;
  final XAIConfig config;

  XAIImages(this.client, this.config);

  @override
  int get maxImagesPerCall => 1;

  @override
  bool get supportsImageEditing => true;

  @override
  List<String> getSupportedSizes() => const <String>[];

  @override
  List<String> getSupportedFormats() => const <String>['url'];

  @override
  bool get supportsImageVariations => false;

  @override
  Future<ImageGenerationResponse> generateImages(
    ImageGenerationRequest request,
  ) {
    return generateImagesWithCallOptions(
      request,
      callOptions: const LLMCallOptions(),
    );
  }

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
        .toList(growable: false);
  }

  @override
  Future<ImageGenerationResponse> generateImagesWithCallOptions(
    ImageGenerationRequest request, {
    required LLMCallOptions callOptions,
  }) async {
    final startedAt = DateTime.now().toUtc();
    final modelUsed = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : config.imageModel;

    final warnings = <LLMWarning>[];
    if (request.size != null) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'size',
        details: 'xAI image models do not support `size`. Use `aspectRatio` via provider options instead.',
      ));
    }
    if (request.seed != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'seed'));
    }
    if (request.negativePrompt != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'negativePrompt'));
    }
    if (request.steps != null) warnings.add(const LLMUnsupportedWarning(feature: 'steps'));
    if (request.guidanceScale != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'guidanceScale'));
    }
    if (request.enhancePrompt != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'enhancePrompt'));
    }
    if (request.style != null) warnings.add(const LLMUnsupportedWarning(feature: 'style'));
    if (request.quality != null) warnings.add(const LLMUnsupportedWarning(feature: 'quality'));

    final baseBody = <String, dynamic>{
      'model': modelUsed,
      'prompt': request.prompt,
      if (request.count != null) 'n': request.count,
      'response_format': 'url',
    };

    final providerOptionsBody = _xaiProviderOptionsBody(config.originalConfig);
    final effectiveBody = callOptions
        .mergedWith(LLMCallOptions(body: providerOptionsBody))
        .mergeIntoRequestBody(baseBody);

    final result = await client.postJsonWithHeaders(
      'images/generations',
      effectiveBody,
      headers: callOptions.headers,
    );

    final json = result.json;
    final data = json['data'];
    if (data is! List) {
      throw ResponseFormatError(
        'Invalid response format from xAI image API: missing data array',
        json.toString(),
      );
    }

    final images = <GeneratedImage>[];
    final providerMetadataImages = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final url = map['url'];
      if (url is! String || url.trim().isEmpty) continue;

      final revisedPrompt = map['revised_prompt'] as String?;
      images.add(
        GeneratedImage(
          url: url,
          revisedPrompt: revisedPrompt,
          format: 'png',
        ),
      );

      if (revisedPrompt != null && revisedPrompt.trim().isNotEmpty) {
        providerMetadataImages.add({'revisedPrompt': revisedPrompt});
      } else {
        providerMetadataImages.add(const <String, dynamic>{});
      }
    }

    return ImageGenerationResponse(
      images: List<GeneratedImage>.unmodifiable(images),
      model: modelUsed,
      revisedPrompt: images.isNotEmpty ? images.first.revisedPrompt : null,
      warnings: List<LLMWarning>.unmodifiable(warnings),
      responses: [
        ImageModelResponseMetadata(
          timestamp: startedAt,
          modelId: modelUsed,
          headers: result.headers.isEmpty ? null : result.headers,
        ),
      ],
      providerMetadata: _providerMetadata(
        endpoint: 'images/generations',
        model: modelUsed,
        images: providerMetadataImages,
      ),
    );
  }

  @override
  Future<ImageGenerationResponse> editImage(ImageEditRequest request) {
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
    final modelUsed = (request.model?.trim().isNotEmpty == true)
        ? request.model!.trim()
        : config.imageModel;

    final warnings = <LLMWarning>[];
    if (request.size != null) {
      warnings.add(const LLMUnsupportedWarning(
        feature: 'size',
        details: 'xAI image models do not support `size`. Use `aspectRatio` via provider options instead.',
      ));
    }
    if (request.mask != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'mask'));
    }

    final imageUrl = _imageInputToUrlOrDataUri(request.image);

    final baseBody = <String, dynamic>{
      'model': modelUsed,
      'prompt': request.prompt,
      if (request.count != null) 'n': request.count,
      'response_format': 'url',
      'image': {
        'url': imageUrl,
        'type': 'image_url',
      },
    };

    final providerOptionsBody = _xaiProviderOptionsBody(config.originalConfig);
    final effectiveBody = callOptions
        .mergedWith(LLMCallOptions(body: providerOptionsBody))
        .mergeIntoRequestBody(baseBody);

    final result = await client.postJsonWithHeaders(
      'images/edits',
      effectiveBody,
      headers: callOptions.headers,
    );

    final json = result.json;
    final data = json['data'];
    if (data is! List) {
      throw ResponseFormatError(
        'Invalid response format from xAI image API: missing data array',
        json.toString(),
      );
    }

    final images = <GeneratedImage>[];
    final providerMetadataImages = <Map<String, dynamic>>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final url = map['url'];
      if (url is! String || url.trim().isEmpty) continue;

      final revisedPrompt = map['revised_prompt'] as String?;
      images.add(
        GeneratedImage(
          url: url,
          revisedPrompt: revisedPrompt,
          format: 'png',
        ),
      );

      if (revisedPrompt != null && revisedPrompt.trim().isNotEmpty) {
        providerMetadataImages.add({'revisedPrompt': revisedPrompt});
      } else {
        providerMetadataImages.add(const <String, dynamic>{});
      }
    }

    return ImageGenerationResponse(
      images: List<GeneratedImage>.unmodifiable(images),
      model: modelUsed,
      revisedPrompt: images.isNotEmpty ? images.first.revisedPrompt : null,
      warnings: List<LLMWarning>.unmodifiable(warnings),
      responses: [
        ImageModelResponseMetadata(
          timestamp: startedAt,
          modelId: modelUsed,
          headers: result.headers.isEmpty ? null : result.headers,
        ),
      ],
      providerMetadata: _providerMetadata(
        endpoint: 'images/edits',
        model: modelUsed,
        images: providerMetadataImages,
      ),
    );
  }

  @override
  Future<ImageGenerationResponse> createVariation(
    ImageVariationRequest request,
  ) async {
    throw const InvalidRequestError(
      'xAI does not support image variations. Use image edits instead.',
    );
  }

  @override
  Future<ImageGenerationResponse> createVariationWithCallOptions(
    ImageVariationRequest request, {
    required LLMCallOptions callOptions,
  }) async {
    throw const InvalidRequestError(
      'xAI does not support image variations. Use image edits instead.',
    );
  }
}

String _imageInputToUrlOrDataUri(ImageInput input) {
  final url = input.url?.trim();
  if (url != null && url.isNotEmpty) return url;

  final bytes = input.data;
  if (bytes == null || bytes.isEmpty) {
    throw const InvalidRequestError('ImageInput must contain url or data.');
  }

  final mediaType = _mediaTypeFromImageFormat(input.format);
  final b64 = base64Encode(bytes);
  return 'data:$mediaType;base64,$b64';
}

String _mediaTypeFromImageFormat(String? format) {
  final f = format?.trim().toLowerCase();
  switch (f) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    case 'png':
    default:
      return 'image/png';
  }
}

Map<String, dynamic>? _xaiProviderOptionsBody(LLMConfig? originalConfig) {
  final options = originalConfig?.providerOptions['xai'];
  if (options == null || options.isEmpty) return null;
  // Do not include known non-body options here.
  final out = <String, dynamic>{};
  for (final entry in options.entries) {
    final key = entry.key;
    if (key.trim().isEmpty) continue;
    if (key == 'jsonSchema' ||
        key == 'embeddingEncodingFormat' ||
        key == 'embeddingDimensions' ||
        key == 'imageModel' ||
        key == 'imageModelId' ||
        key == 'videoModel' ||
        key == 'videoModelId' ||
        key == 'liveSearch' ||
        key == 'searchParameters') {
      continue;
    }
    out[key] = entry.value;
  }
  return out.isEmpty ? null : out;
}

Map<String, dynamic> _providerMetadata({
  required String endpoint,
  required String model,
  required List<Map<String, dynamic>> images,
}) {
  final payload = <String, dynamic>{
    'model': model,
    'endpoint': endpoint,
    if (images.isNotEmpty) 'images': images,
  };

  return {
    'xai': payload,
    'xai.image': payload,
  };
}
