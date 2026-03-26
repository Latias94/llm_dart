import '../common/provider_metadata.dart';
import '../common/provider_options.dart';

final class ImageGenerationRequest {
  final String prompt;
  final int count;
  final String? size;
  final ProviderInvocationOptions? providerOptions;

  const ImageGenerationRequest({
    required this.prompt,
    this.count = 1,
    this.size,
    this.providerOptions,
  });
}

final class GeneratedImage {
  final Uri? uri;
  final List<int>? bytes;
  final String? mediaType;

  const GeneratedImage({
    this.uri,
    this.bytes,
    this.mediaType,
  });
}

final class ImageGenerationResult {
  final List<GeneratedImage> images;
  final ProviderMetadata? providerMetadata;

  ImageGenerationResult({
    required List<GeneratedImage> images,
    this.providerMetadata,
  }) : images = List.unmodifiable(images);
}

abstract interface class ImageModel {
  String get providerId;

  String get modelId;

  Future<ImageGenerationResult> generate(ImageGenerationRequest request);
}
