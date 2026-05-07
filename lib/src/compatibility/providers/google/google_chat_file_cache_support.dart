part of 'google_chat_file_support.dart';

final class _GoogleChatFileCacheSupport {
  static final Map<String, GoogleFile> _fileCache = {};

  GoogleFile? getActive(String cacheKey) {
    final file = _fileCache[cacheKey];
    if (file == null || !file.isActive) {
      return null;
    }

    return file;
  }

  void store({
    required String cacheKey,
    required GoogleFile file,
  }) {
    _fileCache[cacheKey] = file;
  }

  String cacheKey({
    required String displayName,
    required int dataLength,
    required String mimeType,
  }) {
    return '${displayName}_${dataLength}_$mimeType';
  }
}
