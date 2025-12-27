import 'dart:convert';
import 'dart:typed_data';

/// Universal file purpose enumeration supporting multiple providers
enum FilePurpose {
  /// For fine-tuning jobs (OpenAI)
  fineTune('fine-tune'),

  /// For assistants (OpenAI)
  assistants('assistants'),

  /// For vision tasks (OpenAI)
  vision('vision'),

  /// For batch processing (OpenAI)
  batch('batch'),

  /// For user data (OpenAI)
  userData('user_data'),

  /// General purpose file (Anthropic and others)
  general('general');

  const FilePurpose(this.value);
  final String value;

  static FilePurpose fromString(String value) {
    switch (value) {
      case 'fine-tune':
        return FilePurpose.fineTune;
      case 'assistants':
        return FilePurpose.assistants;
      case 'vision':
        return FilePurpose.vision;
      case 'batch':
        return FilePurpose.batch;
      case 'user_data':
        return FilePurpose.userData;
      case 'general':
        return FilePurpose.general;
      default:
        return FilePurpose.general; // Default fallback for unknown purposes
    }
  }
}

/// Universal file status enumeration supporting multiple providers
enum FileStatus {
  /// File has been uploaded successfully
  uploaded('uploaded'),

  /// File has been processed and is ready for use
  processed('processed'),

  /// File processing encountered an error
  error('error'),

  /// File is being processed
  processing('processing'),

  /// File status is unknown or not applicable
  unknown('unknown');

  const FileStatus(this.value);
  final String value;

  static FileStatus fromString(String value) {
    switch (value) {
      case 'uploaded':
        return FileStatus.uploaded;
      case 'processed':
        return FileStatus.processed;
      case 'error':
        return FileStatus.error;
      case 'processing':
        return FileStatus.processing;
      case 'unknown':
        return FileStatus.unknown;
      default:
        return FileStatus.unknown; // Default fallback for unknown statuses
    }
  }
}

/// File object that works across different providers
///
/// This class provides a unified interface for file objects from different
/// providers (OpenAI, Anthropic, etc.) while maintaining backward compatibility.
class FileObject {
  /// The file identifier, which can be referenced in the API endpoints.
  final String id;

  /// The size of the file, in bytes.
  final int sizeBytes;

  /// The timestamp when the file was created.
  final DateTime createdAt;

  /// The name of the file.
  final String filename;

  /// The object type, typically "file".
  final String object;

  /// The intended purpose of the file (may be null for providers that don't support it).
  final FilePurpose? purpose;

  /// The current status of the file (may be null for providers that don't support it).
  final FileStatus? status;

  /// Additional details about the status of the file.
  final String? statusDetails;

  /// MIME type of the file (may be null if not provided).
  final String? mimeType;

  /// Whether the file can be downloaded (may be null if not specified).
  final bool? downloadable;

  /// Provider-specific metadata that doesn't fit into standard fields.
  final Map<String, dynamic>? metadata;

  const FileObject({
    required this.id,
    required this.sizeBytes,
    required this.createdAt,
    required this.filename,
    this.object = 'file',
    this.purpose,
    this.status,
    this.statusDetails,
    this.mimeType,
    this.downloadable,
    this.metadata,
  });

  /// Create from OpenAI file format
  factory FileObject.fromOpenAI(Map<String, dynamic> json) {
    return FileObject(
      id: json['id'] as String,
      sizeBytes: json['bytes'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['created_at'] as int) * 1000),
      filename: json['filename'] as String,
      object: json['object'] as String? ?? 'file',
      purpose: json['purpose'] != null
          ? FilePurpose.fromString(json['purpose'] as String)
          : null,
      status: json['status'] != null
          ? FileStatus.fromString(json['status'] as String)
          : null,
      statusDetails: json['status_details'] as String?,
      metadata: {'provider': 'openai'},
    );
  }

  /// Create from Anthropic file format
  factory FileObject.fromAnthropic(Map<String, dynamic> json) {
    return FileObject(
      id: json['id'] as String,
      sizeBytes: json['size_bytes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      filename: json['filename'] as String,
      object: json['type'] as String? ?? 'file',
      mimeType: json['mime_type'] as String?,
      downloadable: json['downloadable'] as bool?,
      metadata: {'provider': 'anthropic'},
    );
  }

  /// Convert to OpenAI format for backward compatibility
  Map<String, dynamic> toOpenAIJson() {
    return {
      'id': id,
      'bytes': sizeBytes,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'filename': filename,
      'object': object,
      if (purpose != null) 'purpose': purpose!.value,
      if (status != null) 'status': status!.value,
      if (statusDetails != null) 'status_details': statusDetails,
    };
  }

  /// Convert to Anthropic format
  Map<String, dynamic> toAnthropicJson() {
    return {
      'id': id,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
      'filename': filename,
      'type': object,
      if (mimeType != null) 'mime_type': mimeType,
      if (downloadable != null) 'downloadable': downloadable,
    };
  }

  /// Generic JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
      'filename': filename,
      'object': object,
      if (purpose != null) 'purpose': purpose!.value,
      if (status != null) 'status': status!.value,
      if (statusDetails != null) 'status_details': statusDetails,
      if (mimeType != null) 'mime_type': mimeType,
      if (downloadable != null) 'downloadable': downloadable,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileObject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// File upload request that works across providers
class FileUploadRequest {
  /// The file to upload.
  final Uint8List file;

  /// The name of the file to upload.
  final String filename;

  /// The intended purpose of the uploaded file (may be null for providers that don't support it).
  final FilePurpose? purpose;

  /// Additional metadata for the file upload.
  final Map<String, dynamic>? metadata;

  const FileUploadRequest({
    required this.file,
    required this.filename,
    this.purpose,
    this.metadata,
  });

  /// Convert to OpenAI format
  Map<String, dynamic> toOpenAIJson() {
    return {
      'filename': filename,
      if (purpose != null) 'purpose': purpose!.value,
    };
  }

  /// Convert to Anthropic format
  Map<String, dynamic> toAnthropicJson() {
    return {
      'filename': filename,
    };
  }
}

/// File list response that works across providers
class FileListResponse {
  /// The list of files.
  final List<FileObject> data;

  /// The object type.
  final String object;

  /// Pagination information for cursor-based pagination (Anthropic style).
  final String? firstId;
  final String? lastId;
  final bool? hasMore;

  /// Pagination information for offset-based pagination (OpenAI style).
  final int? total;
  final int? limit;
  final int? offset;

  const FileListResponse({
    required this.data,
    this.object = 'list',
    this.firstId,
    this.lastId,
    this.hasMore,
    this.total,
    this.limit,
    this.offset,
  });

  /// Create from OpenAI format
  factory FileListResponse.fromOpenAI(Map<String, dynamic> json) {
    return FileListResponse(
      data: (json['data'] as List)
          .map((item) => FileObject.fromOpenAI(item as Map<String, dynamic>))
          .toList(),
      object: json['object'] as String? ?? 'list',
      total: json['total'] as int?,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
    );
  }

  /// Create from Anthropic format
  factory FileListResponse.fromAnthropic(Map<String, dynamic> json) {
    return FileListResponse(
      data: (json['data'] as List)
          .map((item) => FileObject.fromAnthropic(item as Map<String, dynamic>))
          .toList(),
      object: 'list',
      firstId: json['first_id'] as String?,
      lastId: json['last_id'] as String?,
      hasMore: json['has_more'] as bool?,
    );
  }

  /// Convert to OpenAI format
  Map<String, dynamic> toOpenAIJson() {
    return {
      'data': data.map((file) => file.toOpenAIJson()).toList(),
      'object': object,
      if (total != null) 'total': total,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
  }

  /// Convert to Anthropic format
  Map<String, dynamic> toAnthropicJson() {
    return {
      'data': data.map((file) => file.toAnthropicJson()).toList(),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      if (hasMore != null) 'has_more': hasMore,
    };
  }
}

/// File deletion response that works across providers
class FileDeleteResponse {
  /// The file identifier.
  final String id;

  /// The object type.
  final String object;

  /// Whether the file was successfully deleted.
  final bool deleted;

  /// Error message if deletion failed.
  final String? error;

  const FileDeleteResponse({
    required this.id,
    this.object = 'file',
    required this.deleted,
    this.error,
  });

  /// Create from OpenAI format
  factory FileDeleteResponse.fromOpenAI(Map<String, dynamic> json) {
    return FileDeleteResponse(
      id: json['id'] as String,
      object: json['object'] as String? ?? 'file',
      deleted: json['deleted'] as bool,
    );
  }

  /// Create from boolean result (Anthropic style)
  factory FileDeleteResponse.fromBoolean(String id, bool success,
      {String? error}) {
    return FileDeleteResponse(
      id: id,
      object: 'file',
      deleted: success,
      error: error,
    );
  }

  /// Convert to OpenAI format
  Map<String, dynamic> toOpenAIJson() {
    return {
      'id': id,
      'object': object,
      'deleted': deleted,
    };
  }
}

/// File list query parameters that work across providers
class FileListQuery {
  /// Only return files with the given purpose (OpenAI).
  final FilePurpose? purpose;

  /// A limit on the number of objects to be returned.
  final int? limit;

  /// Sort order by the created_at timestamp of the objects (OpenAI).
  final String? order;

  /// A cursor for use in pagination (OpenAI style).
  final String? after;

  /// Cursor-based pagination (Anthropic style).
  final String? beforeId;
  final String? afterId;

  const FileListQuery({
    this.purpose,
    this.limit,
    this.order,
    this.after,
    this.beforeId,
    this.afterId,
  });

  /// Convert to OpenAI query parameters
  Map<String, dynamic> toOpenAIQueryParameters() {
    final params = <String, dynamic>{};

    if (purpose != null) params['purpose'] = purpose!.value;
    if (limit != null) params['limit'] = limit;
    if (order != null) params['order'] = order;
    if (after != null) params['after'] = after;

    return params;
  }

  /// Convert to Anthropic query parameters
  Map<String, String> toAnthropicQueryParameters() {
    final params = <String, String>{};

    if (beforeId != null) params['before_id'] = beforeId!;
    if (afterId != null) params['after_id'] = afterId!;
    if (limit != null) params['limit'] = limit.toString();

    return params;
  }
}
