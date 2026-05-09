import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';

/// File-upload support for the Google compatibility chat shell.
class GoogleChatFileSupport {
  static final _GoogleChatFileCacheSupport _cacheSupport =
      _GoogleChatFileCacheSupport();

  final GoogleClient client;
  final GoogleConfig config;
  final Future<LLMError> Function(DioException error) errorMapper;
  late final _GoogleChatFileLookupSupport _lookupSupport;
  late final _GoogleChatFileUploadSupport _uploadSupport;

  GoogleChatFileSupport({
    required this.client,
    required this.config,
    required this.errorMapper,
  }) {
    _uploadSupport = _GoogleChatFileUploadSupport(
      client: client,
      config: config,
      errorMapper: errorMapper,
      cacheSupport: _cacheSupport,
    );
    _lookupSupport = _GoogleChatFileLookupSupport(
      client: client,
      cacheSupport: _cacheSupport,
      uploadSupport: _uploadSupport,
    );
  }

  Future<GoogleFile> uploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    return _uploadSupport.uploadFile(
      data: data,
      mimeType: mimeType,
      displayName: displayName,
    );
  }

  Future<GoogleFile?> getOrUploadFile({
    required List<int> data,
    required String mimeType,
    required String displayName,
  }) async {
    return _lookupSupport.getOrUploadFile(
      data: data,
      mimeType: mimeType,
      displayName: displayName,
    );
  }
}

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
