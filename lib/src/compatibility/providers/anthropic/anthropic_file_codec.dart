import '../../../../models/file_models.dart';

/// Anthropic Files API codec for translating provider payloads at the adapter
/// boundary.
final class AnthropicFileCodec {
  const AnthropicFileCodec();

  FileObject fileFromJson(Map<String, dynamic> json) {
    return FileObject(
      id: json['id'] as String,
      sizeBytes: json['size_bytes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      filename: json['filename'] as String,
      object: json['type'] as String? ?? 'file',
      mimeType: json['mime_type'] as String?,
      downloadable: json['downloadable'] as bool?,
      metadata: const {'provider': 'anthropic'},
    );
  }

  Map<String, dynamic> fileToJson(FileObject file) {
    return {
      'id': file.id,
      'size_bytes': file.sizeBytes,
      'created_at': file.createdAt.toIso8601String(),
      'filename': file.filename,
      'type': file.object,
      if (file.mimeType != null) 'mime_type': file.mimeType,
      if (file.downloadable != null) 'downloadable': file.downloadable,
    };
  }

  Map<String, dynamic> uploadRequestToJson(FileUploadRequest request) {
    return {
      'filename': request.filename,
    };
  }

  FileListResponse fileListFromJson(Map<String, dynamic> json) {
    return FileListResponse(
      data: (json['data'] as List)
          .map((item) => fileFromJson(item as Map<String, dynamic>))
          .toList(),
      object: 'list',
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool?,
    );
  }

  Map<String, dynamic> fileListToJson(FileListResponse response) {
    return {
      'data': response.data.map(fileToJson).toList(),
      if (response.firstId != null) 'first_id': response.firstId,
      if (response.lastId != null) 'last_id': response.lastId,
      if (response.hasMore != null) 'has_more': response.hasMore,
    };
  }

  Map<String, String> queryParameters(FileListQuery query) {
    final params = <String, String>{};

    if (query.beforeId != null) params['before_id'] = query.beforeId!;
    if (query.afterId != null) params['after_id'] = query.afterId!;
    if (query.limit != null) params['limit'] = query.limit.toString();

    return params;
  }

  FileDeleteResponse deleteResponseFromBoolean(
    String id,
    bool success, {
    String? error,
  }) {
    return FileDeleteResponse(
      id: id,
      object: 'file',
      deleted: success,
      error: error,
    );
  }
}
