import 'dart:typed_data';

import 'package:llm_dart_transport/dio.dart';

import '../../../../core/capability.dart';
import '../../../../models/file_models.dart';
import '../../../../providers/anthropic/config.dart';
import 'anthropic_file_codec.dart';
import 'client.dart';

export 'anthropic_file_models.dart';

/// Anthropic Files API implementation
///
/// **API Documentation:**
/// - Create File: https://docs.anthropic.com/en/api/files-create
/// - List Files: https://docs.anthropic.com/en/api/files-list
/// - Get Metadata: https://docs.anthropic.com/en/api/files-metadata
/// - Download File: https://docs.anthropic.com/en/api/files-content
/// - Delete File: https://docs.anthropic.com/en/api/files-delete
///
/// This module handles file upload, listing, retrieval, and deletion
/// for Anthropic providers. Note that Anthropic's Files API is currently
/// in beta and requires the `anthropic-beta: files-api-2025-04-14` header.
class AnthropicFiles implements FileManagementCapability {
  final AnthropicClient client;
  final AnthropicConfig config;
  static const _fileCodec = AnthropicFileCodec();

  AnthropicFiles(this.client, this.config);

  /// Upload a file to Anthropic
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-create
  ///
  /// Uploads a file to Anthropic's file storage. The file can then be
  /// referenced in messages for analysis or processing.
  @override
  Future<FileObject> uploadFile(FileUploadRequest request) async {
    final formData = FormData();

    formData.files.add(
      MapEntry(
        'file',
        MultipartFile.fromBytes(
          request.file,
          filename: request.filename,
        ),
      ),
    );

    final responseData = await client.postForm('files', formData);
    return _fileCodec.fileFromJson(responseData);
  }

  @override
  Future<FileListResponse> listFiles([FileListQuery? query]) async {
    String endpoint = 'files';

    if (query != null) {
      final queryParams = _fileCodec.queryParameters(query);
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }
    }

    final responseData = await client.getJson(endpoint);
    return _fileCodec.fileListFromJson(responseData);
  }

  /// List files in the workspace
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-metadata
  ///
  /// Returns metadata for a specific file including size, type, and creation date.
  @override
  Future<FileObject> retrieveFile(String fileId) async {
    final responseData = await client.getJson('files/$fileId');
    return _fileCodec.fileFromJson(responseData);
  }

  /// Get file metadata
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-content
  ///
  /// Downloads the raw content of a file as bytes.
  @override
  Future<List<int>> getFileContent(String fileId) async {
    return await client.getRaw('files/$fileId/content');
  }

  /// Delete a file
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-delete
  ///
  /// Permanently deletes a file from the workspace.
  /// Returns true if successful, false otherwise.
  @override
  Future<FileDeleteResponse> deleteFile(String fileId) async {
    try {
      await client.delete('files/$fileId');
      return _fileCodec.deleteResponseFromBoolean(fileId, true);
    } catch (e) {
      client.logger.warning('Failed to delete file $fileId: $e');
      return _fileCodec.deleteResponseFromBoolean(
        fileId,
        false,
        error: e.toString(),
      );
    }
  }

  /// Upload file from bytes with automatic filename
  Future<FileObject> uploadFileFromBytes(
    List<int> bytes, {
    String? filename,
  }) async {
    return uploadFile(FileUploadRequest(
      file: Uint8List.fromList(bytes),
      filename: filename ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
    ));
  }

  /// Check if a file exists
  Future<bool> fileExists(String fileId) async {
    try {
      await retrieveFile(fileId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get file content as string (for text files)
  Future<String> getFileContentAsString(String fileId) async {
    final bytes = await getFileContent(fileId);
    return String.fromCharCodes(bytes);
  }

  /// Get total storage used by all files
  Future<int> getTotalStorageUsed() async {
    final response = await listFiles();
    return response.data
        .map((file) => file.sizeBytes)
        .fold<int>(0, (sum, bytes) => sum + bytes);
  }

  /// Batch delete multiple files
  Future<Map<String, bool>> deleteFiles(List<String> fileIds) async {
    final results = <String, bool>{};

    for (final fileId in fileIds) {
      final result = await deleteFile(fileId);
      results[fileId] = result.deleted;
    }

    return results;
  }
}
