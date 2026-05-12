import '../common/call_options.dart';
import '../common/provider_metadata.dart';

final class ImageGenerationRequest {
  final String prompt;
  final int count;
  final String? size;
  final CallOptions callOptions;

  const ImageGenerationRequest({
    required this.prompt,
    this.count = 1,
    this.size,
    this.callOptions = const CallOptions(),
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

  Future<ImageGenerationResult> doGenerate(ImageGenerationRequest request);
}
