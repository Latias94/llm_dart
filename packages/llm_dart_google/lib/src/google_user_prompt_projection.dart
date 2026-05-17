import 'package:llm_dart_provider/llm_dart_provider.dart';

import 'google_binary_part_encoder.dart';

final class GoogleUserPromptProjection {
  final GoogleBinaryPartEncoder binaryEncoder;

  const GoogleUserPromptProjection({
    this.binaryEncoder = const GoogleBinaryPartEncoder(),
  });

  Map<String, Object?> encodePart(PromptPart part) {
    if (part is TextPromptPart) {
      return {
        'text': part.text,
      };
    }

    if (part is ImagePromptPart) {
      return binaryEncoder.encodeUserBinaryPart(
        mediaType: part.mediaType == 'image/*' ? 'image/jpeg' : part.mediaType,
        data: part.data,
      );
    }

    if (part is FilePromptPart) {
      return binaryEncoder.encodeUserBinaryPart(
        mediaType: part.mediaType,
        data: part.data,
      );
    }

    throw UnsupportedError(
      'Google user prompt part ${part.runtimeType} is not supported yet.',
    );
  }
}
