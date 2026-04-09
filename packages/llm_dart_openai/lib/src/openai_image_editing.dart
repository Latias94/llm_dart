import 'package:llm_dart_core/llm_dart_core.dart';

enum OpenAIImageInputFidelity {
  low('low'),
  high('high');

  const OpenAIImageInputFidelity(this.value);

  final String value;
}

final class OpenAIImageEditInput {
  final List<int> bytes;
  final String mediaType;
  final String? filename;

  const OpenAIImageEditInput({
    required this.bytes,
    this.mediaType = 'image/png',
    this.filename,
  });
}

final class OpenAIImageEditRequest {
  final String prompt;
  final List<OpenAIImageEditInput> images;
  final OpenAIImageEditInput? mask;
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
