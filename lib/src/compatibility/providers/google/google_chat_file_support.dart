import 'dart:convert';

import 'package:llm_dart_transport/dio.dart';

import '../../../../core/llm_error.dart';
import '../../../../providers/google/config.dart';
import 'client.dart';

part 'google_chat_file_cache_support.dart';
part 'google_chat_file_lookup_support.dart';
part 'google_chat_file_model.dart';
part 'google_chat_file_upload_support.dart';

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
