part of 'images.dart';

final class _GoogleImagesInlineImageSupport {
  const _GoogleImagesInlineImageSupport();

  _GoogleInlineImageInput? encode(
    ImageInput image,
    GoogleImageSupport support, {
    required String urlInputErrorMessage,
  }) {
    if (image.data != null) {
      return _GoogleInlineImageInput(
        base64: base64Encode(image.data!),
        mimeType: support.mimeTypeFromFormat(image.format ?? 'png'),
      );
    }

    if (image.url != null) {
      throw UnsupportedError(urlInputErrorMessage);
    }

    return null;
  }
}

final class _GoogleInlineImageInput {
  final String base64;
  final String mimeType;

  const _GoogleInlineImageInput({
    required this.base64,
    required this.mimeType,
  });
}
