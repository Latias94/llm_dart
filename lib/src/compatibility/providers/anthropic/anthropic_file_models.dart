import 'dart:typed_data';

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
