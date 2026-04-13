import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';

/// Google file upload response.
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

/// File-upload support for the Google compatibility chat shell.
class GoogleChatFileSupport {
  static final Map<String, GoogleFile> _fileCache = {};

  final GoogleClient client;
  final GoogleConfig config;
  final Future<LLMError> Function(DioException error) errorMapper;

  GoogleChatFileSupport({
    required this.client,
    required this.config,
    required this.errorMapper,
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
      _fileCache[_cacheKey(
        displayName: displayName,
        dataLength: data.length,
        mimeType: mimeType,
      )] = uploadedFile;

      return uploadedFile;
    } on DioException catch (e) {
      throw await errorMapper(e);
    } catch (e) {
      throw GenericError('File upload error: $e');
    }
  }

  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    final cacheKey = _cacheKey(
      displayName: displayName,
      dataLength: data.length,
      mimeType: mimeType,
    );

    final cachedFile = _fileCache[cacheKey];
    if (cachedFile != null && cachedFile.isActive) {
      return cachedFile;
    }

    try {
      return await uploadFile(
        data: data,
        mimeType: mimeType,
        displayName: displayName,
      );
    } catch (e) {
      client.logger.warning('File upload failed: $e');
      return null;
    }
  }

  String _cacheKey({
    required String displayName,
    required int dataLength,
    required String mimeType,
  }) {
    return '${displayName}_${dataLength}_$mimeType';
  }
}
