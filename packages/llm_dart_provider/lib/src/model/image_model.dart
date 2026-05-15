import '../common/call_options.dart';
import '../common/model_warning.dart';
import '../common/provider_metadata.dart';
import '../common/usage_stats.dart';
import 'model_response_metadata.dart';

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

  Future<ImageGenerationResult> doGenerate(ImageGenerationRequest request);
}
