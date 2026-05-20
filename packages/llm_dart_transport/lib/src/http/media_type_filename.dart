abstract final class MediaTypeFilename {
  static String build({
    required String basename,
    required String mediaType,
    required Map<String, String> extensionsByMediaType,
    String fallbackExtension = 'bin',
  }) {
    return '$basename.${extensionFor(
      mediaType,
      extensionsByMediaType: extensionsByMediaType,
      fallbackExtension: fallbackExtension,
    )}';
  }

  static String extensionFor(
    String mediaType, {
    required Map<String, String> extensionsByMediaType,
    String fallbackExtension = 'bin',
  }) {
    return extensionsByMediaType[normalize(mediaType)] ?? fallbackExtension;
  }

  static String normalize(String mediaType) {
    return mediaType.split(';').first.trim().toLowerCase();
  }
}
