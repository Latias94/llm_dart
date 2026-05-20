import 'package:llm_dart_provider/llm_dart_provider.dart';
import 'package:llm_dart_transport/llm_dart_transport.dart';

void validateOpenAIImageEditInput(
  ImageGenerationInput input,
  String parameterName,
) {
  if (input.uri != null) {
    throw ArgumentError.value(
      input.uri,
      '$parameterName.uri',
      'OpenAI image editing inputs must provide image bytes.',
    );
  }

  final bytes = input.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw ArgumentError.value(
      input.bytes,
      '$parameterName.bytes',
      'OpenAI image editing inputs must provide non-empty bytes.',
    );
  }

  if (!input.mediaType.startsWith('image/')) {
    throw ArgumentError.value(
      input.mediaType,
      '$parameterName.mediaType',
      'OpenAI image editing inputs must use an image/* media type.',
    );
  }
}

void validateOpenAIImageOutputCompression(
  int outputCompression,
  String parameterName,
) {
  if (outputCompression < 0 || outputCompression > 100) {
    throw ArgumentError.value(
      outputCompression,
      parameterName,
      'OpenAI image outputCompression must be between 0 and 100.',
    );
  }
}

String buildOpenAIImageFilename(String mediaType) {
  return MediaTypeFilename.build(
    basename: 'image',
    mediaType: mediaType,
    extensionsByMediaType: const {
      'image/png': 'png',
      'image/jpeg': 'jpeg',
      'image/jpg': 'jpg',
      'image/webp': 'webp',
      'image/gif': 'gif',
    },
  );
}
