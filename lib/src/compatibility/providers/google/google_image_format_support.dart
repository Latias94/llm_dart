part of 'google_image_support.dart';

final class _GoogleImageFormatSupport {
  const _GoogleImageFormatSupport();

  String convertSizeToAspectRatio(String size) {
    switch (size.toLowerCase()) {
      case '256x256':
      case '512x512':
      case '1024x1024':
        return '1:1';
      case '768x1344':
      case '1024x1792':
        return '3:4';
      case '1344x768':
      case '1792x1024':
        return '4:3';
      case '640x1536':
        return '9:16';
      case '1536x640':
        return '16:9';
      default:
        final parts = size.split('x');
        if (parts.length == 2) {
          final width = int.tryParse(parts[0]);
          final height = int.tryParse(parts[1]);
          if (width != null && height != null) {
            if (width == height) return '1:1';
            if (width > height) {
              final ratio = width / height;
              if (ratio > 1.7) return '16:9';
              return '4:3';
            } else {
              final ratio = height / width;
              if (ratio > 1.7) return '9:16';
              return '3:4';
            }
          }
        }
        return '1:1';
    }
  }

  String extractFormatFromMimeType(String? mimeType) {
    if (mimeType == null) return 'png';

    if (mimeType.contains('jpeg') || mimeType.contains('jpg')) {
      return 'jpeg';
    } else if (mimeType.contains('webp')) {
      return 'webp';
    } else {
      return 'png';
    }
  }

  String mimeTypeFromFormat(String format) {
    switch (format.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'png':
      default:
        return 'image/png';
    }
  }
}
