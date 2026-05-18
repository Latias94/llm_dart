import '../common/call_options.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import 'model_response_metadata.dart';

class ImageGenerationInput {
  final List<int>? bytes;
  final Uri? uri;
  final String mediaType;
  final String? filename;

  const ImageGenerationInput.bytes(
    this.bytes, {
    this.mediaType = 'image/png',
    this.filename,
  }) : uri = null;

  const ImageGenerationInput.uri(
    this.uri, {
    this.mediaType = 'image/*',
    this.filename,
  }) : bytes = null;
}

final class ImageGenerationRequest {
  final String? prompt;
  final int count;
  final String? size;
  final String? aspectRatio;
  final int? seed;
  final List<ImageGenerationInput> files;
  final ImageGenerationInput? mask;
  final CallOptions callOptions;

  ImageGenerationRequest({
    this.prompt,
    this.count = 1,
    this.size,
    this.aspectRatio,
    this.seed,
    List<ImageGenerationInput> files = const [],
    this.mask,
    this.callOptions = const CallOptions(),
  }) : files = List<ImageGenerationInput>.unmodifiable(files);
}

final class GeneratedImage {
  final Uri? uri;
  final List<int>? bytes;
  final String? mediaType;
  final ProviderMetadata? providerMetadata;

  const GeneratedImage({
    this.uri,
    this.bytes,
    this.mediaType,
    this.providerMetadata,
  });
}

final class ImageGenerationResult {
  final List<GeneratedImage> images;
  final UsageStats? usage;
  final List<ModelWarning> warnings;
  final ModelResponseMetadata? responseMetadata;
  final ProviderMetadata? providerMetadata;

  ImageGenerationResult({
    required List<GeneratedImage> images,
    this.usage,
    List<ModelWarning> warnings = const [],
    this.responseMetadata,
    this.providerMetadata,
  })  : images = List.unmodifiable(images),
        warnings = List.unmodifiable(warnings);
}

abstract interface class ImageModel {
  String get providerId;

  String get modelId;

  /// Maximum number of images this model can generate in a single call.
  ///
  /// A null value means callers should use their own conservative default.
  int? get maxImagesPerCall;

  Future<ImageGenerationResult> doGenerate(ImageGenerationRequest request);
}
