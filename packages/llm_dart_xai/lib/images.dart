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
        details:
            'xAI image models do not support `size`. Use `aspectRatio` instead.',
      ));
    }
    if (request.seed != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'seed'));
    }
    if (request.negativePrompt != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'negativePrompt'));
    }
    if (request.steps != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'steps'));
    }
    if (request.guidanceScale != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'guidanceScale'));
    }
    if (request.enhancePrompt != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'enhancePrompt'));
    }
    if (request.style != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'style'));
    }
    if (request.quality != null) {
      warnings.add(const LLMUnsupportedWarning(feature: 'quality'));
    }

    final baseBody = <String, dynamic>{
      'model': modelUsed,
      'prompt': request.prompt,
      if (request.count != null) 'n': request.count,
      'response_format': 'url',
    };

    final mergedProviderOptions =
        _mergeProviderOptions(config.originalConfig, request.providerOptions);
    final xaiOptions = mergedProviderOptions['xai'];
    final providerOptionsBody = _xaiProviderOptionsBody(xaiOptions);

    var requestBody = Map<String, dynamic>.from(baseBody);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      requestBody.addAll(providerOptionsBody);
    }

    final ar = request.aspectRatio?.trim();
    if (ar != null && ar.isNotEmpty) {
      requestBody['aspect_ratio'] = ar;
    }

    final effectiveBody = callOptions.mergeIntoRequestBody(requestBody);

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
        details:
            'xAI image models do not support `size`. Use `aspectRatio` instead.',
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

    final mergedProviderOptions =
        _mergeProviderOptions(config.originalConfig, request.providerOptions);
    final xaiOptions = mergedProviderOptions['xai'];
    final providerOptionsBody = _xaiProviderOptionsBody(xaiOptions);

    var requestBody = Map<String, dynamic>.from(baseBody);
    if (providerOptionsBody != null && providerOptionsBody.isNotEmpty) {
      requestBody.addAll(providerOptionsBody);
    }

    final ar = request.aspectRatio?.trim();
    if (ar != null && ar.isNotEmpty) {
      requestBody['aspect_ratio'] = ar;
    }

    final effectiveBody = callOptions.mergeIntoRequestBody(requestBody);

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

Map<String, dynamic>? _xaiProviderOptionsBody(
    Map<String, dynamic>? xaiOptions) {
  final options = xaiOptions;
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

Map<String, Map<String, dynamic>> _mergeProviderOptions(
  LLMConfig? originalConfig,
  ProviderOptions requestProviderOptions,
) {
  final base =
      originalConfig?.providerOptions ?? const <String, Map<String, dynamic>>{};
  if (base.isEmpty) return requestProviderOptions;
  if (requestProviderOptions.isEmpty) return base;

  final out = <String, Map<String, dynamic>>{};
  for (final entry in base.entries) {
    out[entry.key] = Map<String, dynamic>.from(entry.value);
  }
  for (final entry in requestProviderOptions.entries) {
    final key = entry.key;
    final existing = out[key];
    if (existing == null) {
      out[key] = Map<String, dynamic>.from(entry.value);
    } else {
      out[key] = {...existing, ...entry.value};
    }
  }
  return out;
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

  return {'xai': payload};
}
