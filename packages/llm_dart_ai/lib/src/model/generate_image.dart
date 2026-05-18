import 'package:llm_dart_provider/llm_dart_provider.dart';

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
  if (count < 1) {
    throw ArgumentError.value(
      count,
      'count',
      'generateImage(...) requires count >= 1.',
    );
  }

  return model.doGenerate(
    ImageGenerationRequest(
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
