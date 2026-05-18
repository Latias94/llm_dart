import 'package:llm_dart_provider/llm_dart_provider.dart';

enum OpenAIImageInputFidelity {
  low('low'),
  high('high');

  const OpenAIImageInputFidelity(this.value);

  final String value;
}

final class OpenAIImageEditInput extends ImageGenerationInput {
  const OpenAIImageEditInput({
    required List<int> bytes,
    String mediaType = 'image/png',
    String? filename,
  }) : super.bytes(
          bytes,
          mediaType: mediaType,
          filename: filename,
        );
}

final class OpenAIImageEditRequest {
  final String prompt;
  final List<ImageGenerationInput> images;
  final ImageGenerationInput? mask;
  final int count;
  final String? size;
  final OpenAIImageInputFidelity? inputFidelity;
  final int? partialImages;
  final int? outputCompression;
  final CallOptions callOptions;

  const OpenAIImageEditRequest({
    required this.prompt,
    required this.images,
    this.mask,
    this.count = 1,
    this.size,
    this.inputFidelity,
    this.partialImages,
    this.outputCompression,
    this.callOptions = const CallOptions(),
  });
}
