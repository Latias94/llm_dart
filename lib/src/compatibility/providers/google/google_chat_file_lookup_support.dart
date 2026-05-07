part of 'google_chat_file_support.dart';

final class _GoogleChatFileLookupSupport {
  final GoogleClient client;
  final _GoogleChatFileCacheSupport cacheSupport;
  final _GoogleChatFileUploadSupport uploadSupport;

  _GoogleChatFileLookupSupport({
    required this.client,
    required this.cacheSupport,
    required this.uploadSupport,
  });

  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    final cacheKey = cacheSupport.cacheKey(
      displayName: displayName,
      dataLength: data.length,
      mimeType: mimeType,
    );

    final cachedFile = cacheSupport.getActive(cacheKey);
    if (cachedFile != null) {
      return cachedFile;
    }

    try {
      return await uploadSupport.uploadFile(
        data: data,
        mimeType: mimeType,
        displayName: displayName,
      );
    } catch (e) {
      client.logger.warning('File upload failed: $e');
      return null;
    }
  }
}
