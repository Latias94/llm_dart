import 'package:llm_dart_provider/llm_dart_provider.dart';

final class GoogleImageEditInput extends ImageGenerationInput {
  const GoogleImageEditInput.bytes(
    super.bytes, {
    super.mediaType = 'image/png',
    super.filename,
  }) : super.bytes();

  const GoogleImageEditInput.uri(
    super.uri, {
    super.mediaType = 'image/*',
    super.filename,
  }) : super.uri();
}

final class GoogleImageEditRequest {
  final String prompt;
  final List<ImageGenerationInput> images;
  final int count;
  final String? aspectRatio;
  final int? seed;
  final CallOptions callOptions;

  const GoogleImageEditRequest({
    required this.prompt,
    required this.images,
    this.count = 1,
    this.aspectRatio,
    this.seed,
    this.callOptions = const CallOptions(),
  });
}

final class GoogleImageVariationRequest {
  static const String defaultPrompt =
      'Create variations of these images while preserving the main subject and style but changing composition and details.';

  final List<ImageGenerationInput> images;
  final String prompt;
  final int count;
  final String? aspectRatio;
  final int? seed;
  final CallOptions callOptions;

  const GoogleImageVariationRequest({
    required this.images,
    this.prompt = defaultPrompt,
    this.count = 1,
    this.aspectRatio,
    this.seed,
    this.callOptions = const CallOptions(),
  });
}
