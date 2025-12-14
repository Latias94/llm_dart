import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

import '../client/google_client.dart';

/// Metadata for a file stored in the Gemini Files API.
class GoogleFile {
  final String name;
  final String displayName;
  final String mimeType;
  final int sizeBytes;
  final String state;
  final String? uri;

  const GoogleFile({
    required this.name,
    required this.displayName,
    required this.mimeType,
    required this.sizeBytes,
    required this.state,
    this.uri,
  });

  factory GoogleFile.fromJson(Map<String, dynamic> json) => GoogleFile(
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: int.parse(json['sizeBytes'] as String),
        state: json['state'] as String,
        uri: json['uri'] as String?,
      );

  bool get isActive => state == 'ACTIVE';
}

/// Explicit helper for working with the Gemini Files API.
///
/// This is a thin convenience layer around the low-level HTTP client.
class GoogleFilesClient {
  final GoogleClient client;

  GoogleFilesClient(this.client);

  /// Upload a file to the Gemini Files API and return its metadata.
  ///
  /// The returned [GoogleFile.name] can be used as `fileUri` in `fileData`
  /// parts for chat or other multimodal requests.
  Future<GoogleFile> uploadBytes({
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
        'metadata': metadata,
        'data': MultipartFile.fromBytes(
          data,
          filename: displayName,
        ),
      });

      final response = await client.dio.post(
        'upload/v1beta/files?key=${client.config.apiKey}',
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
      return GoogleFile.fromJson(fileData);
    } on DioException catch (e) {
      client.logger.severe('Google Files upload failed: ${e.message}', e);
      throw await DioErrorHandler.handleDioError(e, 'Google Files');
    } catch (e) {
      client.logger.severe('Google Files upload error: $e', e);
      throw GenericError('File upload error: $e');
    }
  }
}
