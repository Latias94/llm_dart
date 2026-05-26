import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'non_text_request_support.dart';

final class GenerateImageRequest {
  final ImageModel model;
  final String prompt;
  final int count;
  final String? size;
  final String? aspectRatio;
  final int? seed;
  final List<ImageGenerationInput> files;
  final ImageGenerationInput? mask;
  final CallOptions callOptions;

  GenerateImageRequest({
    required this.model,
    required this.prompt,
    this.count = 1,
    this.size,
    this.aspectRatio,
    this.seed,
    List<ImageGenerationInput> files = const [],
    this.mask,
    this.callOptions = const CallOptions(),
  }) : files = List.unmodifiable(files) {
    _validate();
  }

  ImageGenerationRequest toProviderRequest() {
    return ImageGenerationRequest(
      prompt: prompt,
      count: count,
      size: size,
      aspectRatio: aspectRatio,
      seed: seed,
      files: files,
      mask: mask,
      callOptions: callOptions,
    );
  }

  void _validate() {
    if (count < 1) {
      throw ArgumentError.value(
        count,
        'count',
        'GenerateImageRequest requires count >= 1.',
      );
    }

    final max = model.maxImagesPerCall;
    if (max != null && count > max) {
      throw ArgumentError.value(
        count,
        'count',
        'GenerateImageRequest count is $count, but '
            '${model.providerId}:${model.modelId} can generate at most $max.',
      );
    }

    requireDescribedModelCapability(
      model: model,
      kind: ModelCapabilityKind.image,
      usageContext: 'GenerateImageRequest',
    );

    if (files.isNotEmpty || mask != null) {
      requireDescribedModelCapability(
        model: model,
        kind: ModelCapabilityKind.image,
        featureId: ModelCapabilityFeatureIds.imageEditing,
        usageContext: 'GenerateImageRequest.files/mask',
      );
    }
  }
}

Future<ImageGenerationResult> generateImage({
  required ImageModel model,
  required String prompt,
  int count = 1,
  String? size,
  String? aspectRatio,
  int? seed,
  List<ImageGenerationInput> files = const [],
  ImageGenerationInput? mask,
  CallOptions callOptions = const CallOptions(),
}) {
  return generateImageForRequest(
    GenerateImageRequest(
      model: model,
      prompt: prompt,
      count: count,
      size: size,
      aspectRatio: aspectRatio,
      seed: seed,
      files: files,
      mask: mask,
      callOptions: callOptions,
    ),
  );
}

Future<ImageGenerationResult> generateImageForRequest(
  GenerateImageRequest request,
) {
  return request.model.doGenerate(request.toProviderRequest());
}
