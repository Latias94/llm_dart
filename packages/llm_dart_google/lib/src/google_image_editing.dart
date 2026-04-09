import 'package:llm_dart_core/llm_dart_core.dart';

final class GoogleImageEditInput {
  final List<int>? bytes;
  final Uri? uri;
  final String mediaType;

  const GoogleImageEditInput.bytes(
    this.bytes, {
    this.mediaType = 'image/png',
  }) : uri = null;

  const GoogleImageEditInput.uri(
    this.uri, {
    this.mediaType = 'image/*',
  }) : bytes = null;
}

final class GoogleImageEditRequest {
  final String prompt;
  final List<GoogleImageEditInput> images;
  final int count;
  final CallOptions callOptions;

  const GoogleImageEditRequest({
    required this.prompt,
    required this.images,
    this.count = 1,
    this.callOptions = const CallOptions(),
  });
}

final class GoogleImageVariationRequest {
  static const String defaultPrompt =
      'Create variations of these images while preserving the main subject and style but changing composition and details.';

  final List<GoogleImageEditInput> images;
  final String prompt;
  final int count;
  final CallOptions callOptions;

  const GoogleImageVariationRequest({
    required this.images,
    this.prompt = defaultPrompt,
    this.count = 1,
    this.callOptions = const CallOptions(),
  });
}
