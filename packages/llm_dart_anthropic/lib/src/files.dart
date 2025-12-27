import 'dart:typed_data';
import 'package:dio/dio.dart';

import 'package:llm_dart_anthropic_compatible/llm_dart_anthropic_compatible.dart';
import 'package:llm_dart_core/models/file_models.dart';

/// Anthropic-specific file object
///
/// **API Reference:** https://docs.anthropic.com/en/api/files-create
///
/// Represents a file uploaded to Anthropic's Files API.
/// Note: This is separate from OpenAI's file format due to API differences.
class AnthropicFile {
  /// Unique file identifier
  final String id;

  /// Original filename
  final String filename;

  /// MIME type of the file
  final String mimeType;

  /// File size in bytes
  final int sizeBytes;

  /// File creation timestamp (ISO 8601 format)
  final DateTime createdAt;

  /// Whether the file can be downloaded
  final bool downloadable;

  /// Object type (always "file")
  final String type;

  const AnthropicFile({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.downloadable,
    this.type = 'file',
  });

  factory AnthropicFile.fromJson(Map<String, dynamic> json) {
    return AnthropicFile(
      id: json['id'] as String,
      filename: json['filename'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      downloadable: json['downloadable'] as bool? ?? false,
      type: json['type'] as String? ?? 'file',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
      'downloadable': downloadable,
      'type': type,
    };
  }

  @override
  String toString() =>
      'AnthropicFile(id: $id, filename: $filename, size: $sizeBytes bytes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnthropicFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Anthropic file list response
///
/// **API Reference:** https://docs.anthropic.com/en/api/files-list
class AnthropicFileListResponse {
  /// List of files
  final List<AnthropicFile> data;

  /// ID of the first file in this page
  final String? firstId;

  /// ID of the last file in this page
  final String? lastId;

  /// Whether there are more results available
  final bool hasMore;

  const AnthropicFileListResponse({
    required this.data,
    this.firstId,
    this.lastId,
    required this.hasMore,
  });

  factory AnthropicFileListResponse.fromJson(Map<String, dynamic> json) {
    return AnthropicFileListResponse(
      data: (json['data'] as List)
          .map((item) => AnthropicFile.fromJson(item as Map<String, dynamic>))
          .toList(),
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((file) => file.toJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      'has_more': hasMore,
    };
  }
}

/// Anthropic file upload request
class AnthropicFileUploadRequest {
  /// File data as bytes
  final Uint8List file;

  /// Original filename
  final String filename;

  const AnthropicFileUploadRequest({
    required this.file,
    required this.filename,
  });
}

/// Anthropic file list query parameters
///
/// **API Reference:** https://docs.anthropic.com/en/api/files-list
class AnthropicFileListQuery {
  /// ID of the object to use as a cursor for pagination (before)
  final String? beforeId;

  /// ID of the object to use as a cursor for pagination (after)
  final String? afterId;

  /// Number of items to return per page (1-1000, default 20)
  final int? limit;

  const AnthropicFileListQuery({
    this.beforeId,
    this.afterId,
    this.limit,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (beforeId != null) params['before_id'] = beforeId!;
    if (afterId != null) params['after_id'] = afterId!;
    if (limit != null) params['limit'] = limit.toString();
    return params;
  }
}

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
class AnthropicFiles {
  final AnthropicClient client;
  final AnthropicConfig config;

  AnthropicFiles(this.client, this.config);

  /// Upload a file to Anthropic
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-create
  ///
  /// Uploads a file to Anthropic's file storage. The file can then be
  /// referenced in messages for analysis or processing.
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
    return FileObject.fromAnthropic(responseData);
  }

  Future<FileListResponse> listFiles([FileListQuery? query]) async {
    String endpoint = 'files';

    if (query != null) {
      final queryParams = query.toAnthropicQueryParameters();
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }
    }

    final responseData = await client.getJson(endpoint);
    return FileListResponse.fromAnthropic(responseData);
  }

  /// List files in the workspace
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-metadata
  ///
  /// Returns metadata for a specific file including size, type, and creation date.
  Future<FileObject> retrieveFile(String fileId) async {
    final responseData = await client.getJson('files/$fileId');
    return FileObject.fromAnthropic(responseData);
  }

  /// Get file metadata
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-content
  ///
  /// Downloads the raw content of a file as bytes.
  Future<List<int>> getFileContent(String fileId) async {
    return await client.getRaw('files/$fileId/content');
  }

  /// Delete a file
  ///
  /// **API Reference:** https://docs.anthropic.com/en/api/files-delete
  ///
  /// Permanently deletes a file from the workspace.
  /// Returns true if successful, false otherwise.
  Future<FileDeleteResponse> deleteFile(String fileId) async {
    try {
      await client.delete('files/$fileId');
      return FileDeleteResponse.fromBoolean(fileId, true);
    } catch (e) {
      client.logger.warning('Failed to delete file $fileId: $e');
      return FileDeleteResponse.fromBoolean(fileId, false, error: e.toString());
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
