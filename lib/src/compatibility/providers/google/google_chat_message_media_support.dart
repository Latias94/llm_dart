part of 'google_chat_message_codec.dart';

final class _GoogleChatMessageMediaSupport {
  const _GoogleChatMessageMediaSupport();

  Map<String, dynamic> convertImage(ImageMime mime, List<int> data) {
    final supportedFormats = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/webp',
    ];
    if (!supportedFormats.contains(mime.mimeType)) {
      return {
        'text':
            '[Unsupported image format: ${mime.mimeType}. Supported formats: ${supportedFormats.join(', ')}]',
      };
    }

    return {
      'inlineData': {
        'mimeType': mime.mimeType,
        'data': base64Encode(data),
      },
    };
  }

  Map<String, dynamic> convertFile(
    FileMime mime,
    List<int> data, {
    required int maxInlineDataSize,
  }) {
    if (data.length > maxInlineDataSize) {
      return {
        'text':
            '[File too large: ${data.length} bytes. Maximum size: $maxInlineDataSize bytes]',
      };
    } else if (mime.isDocument || mime.isAudio || mime.isVideo) {
      return {
        'inlineData': {
          'mimeType': mime.mimeType,
          'data': base64Encode(data),
        },
      };
    }

    return {
      'text':
          '[File type ${mime.description} (${mime.mimeType}) may not be supported by Google AI]',
    };
  }

  Map<String, dynamic> convertImageUrl(String url) {
    return {
      'text':
          '[Image URL not supported by Google. Please upload the image directly: $url]',
    };
  }
}
