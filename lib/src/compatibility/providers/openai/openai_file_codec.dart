import '../../../../models/file_models.dart';

/// OpenAI Files API codec for translating provider payloads at the adapter
/// boundary.
final class OpenAIFileCodec {
  const OpenAIFileCodec();

  FileObject fileFromJson(Map<String, dynamic> json) {
    return FileObject(
      id: json['id'] as String,
      sizeBytes: json['bytes'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] as int) * 1000,
      ),
      filename: json['filename'] as String,
      object: json['object'] as String? ?? 'file',
      purpose: json['purpose'] != null
          ? FilePurpose.fromString(json['purpose'] as String)
          : null,
      status: json['status'] != null
          ? FileStatus.fromString(json['status'] as String)
          : null,
      statusDetails: json['status_details'] as String?,
      metadata: const {'provider': 'openai'},
    );
  }

  Map<String, dynamic> fileToJson(FileObject file) {
    return {
      'id': file.id,
      'bytes': file.sizeBytes,
      'created_at': file.createdAt.millisecondsSinceEpoch ~/ 1000,
      'filename': file.filename,
      'object': file.object,
      if (file.purpose != null) 'purpose': file.purpose!.value,
      if (file.status != null) 'status': file.status!.value,
      if (file.statusDetails != null) 'status_details': file.statusDetails,
    };
  }

  Map<String, dynamic> uploadRequestToJson(FileUploadRequest request) {
    return {
      'filename': request.filename,
      if (request.purpose != null) 'purpose': request.purpose!.value,
    };
  }

  FileListResponse fileListFromJson(Map<String, dynamic> json) {
    return FileListResponse(
      data: (json['data'] as List)
          .map((item) => fileFromJson(item as Map<String, dynamic>))
          .toList(),
      object: json['object'] as String? ?? 'list',
      total: json['total'] as int?,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
    );
  }

  Map<String, dynamic> fileListToJson(FileListResponse response) {
    return {
      'data': response.data.map(fileToJson).toList(),
      'object': response.object,
      if (response.total != null) 'total': response.total,
      if (response.limit != null) 'limit': response.limit,
      if (response.offset != null) 'offset': response.offset,
    };
  }

  FileDeleteResponse deleteResponseFromJson(Map<String, dynamic> json) {
    return FileDeleteResponse(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'file',
      deleted: json['deleted'] as bool,
    );
  }

  Map<String, dynamic> deleteResponseToJson(FileDeleteResponse response) {
    return {
      'id': response.id,
      'object': response.object,
      'deleted': response.deleted,
    };
  }

  Map<String, dynamic> queryParameters(FileListQuery query) {
    final params = <String, dynamic>{};

    if (query.purpose != null) params['purpose'] = query.purpose!.value;
    if (query.limit != null) params['limit'] = query.limit;
    if (query.order != null) params['order'] = query.order;
    if (query.after != null) params['after'] = query.after;

    return params;
  }
}
