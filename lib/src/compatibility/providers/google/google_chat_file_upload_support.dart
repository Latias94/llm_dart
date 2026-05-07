part of 'google_chat_file_support.dart';

final class _GoogleChatFileUploadSupport {
  final GoogleClient client;
  final GoogleConfig config;
  final Future<LLMError> Function(DioException error) errorMapper;
  final _GoogleChatFileCacheSupport cacheSupport;

  _GoogleChatFileUploadSupport({
    required this.client,
    required this.config,
    required this.errorMapper,
    required this.cacheSupport,
  });

  Future<GoogleFile> uploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    try {
      final metadata = {
        'file': {
          'displayName': displayName,
          'mimeType': mimeType,
        }
      };

      final formData = FormData.fromMap({
        'metadata': jsonEncode(metadata),
        'data': MultipartFile.fromBytes(
          data,
          filename: displayName,
        ),
      });

      final response = await client.dio.post(
        'upload/v1beta/files?key=${config.apiKey}',
        data: formData,
        options: Options(
          headers: {
            'X-Goog-Upload-Protocol': 'multipart',
          },
        ),
      );

      if (response.statusCode != 200) {
        final errorMessage = response.data?['error']?['message'] ??
            'File upload failed: ${response.statusCode}';
        throw ProviderError(errorMessage);
      }

      final fileData = response.data['file'] as Map<String, dynamic>;
      final uploadedFile = GoogleFile.fromJson(fileData);
      cacheSupport.store(
        cacheKey: cacheSupport.cacheKey(
          displayName: displayName,
          dataLength: data.length,
          mimeType: mimeType,
        ),
        file: uploadedFile,
      );

      return uploadedFile;
    } on DioException catch (e) {
      throw await errorMapper(e);
    } catch (e) {
      throw GenericError('File upload error: $e');
    }
  }
}
