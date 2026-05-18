import 'dart:typed_data';

import 'anthropic_value.dart';

final class AnthropicFileUpload {
  final List<int> bytes;
  final String filename;
  final String mediaType;

  const AnthropicFileUpload({
    required this.bytes,
    required this.filename,
    this.mediaType = 'application/octet-stream',
  });
}

final class AnthropicFileDescriptor {
  final String id;
  final String type;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;
  final bool downloadable;

  const AnthropicFileDescriptor({
    required this.id,
    required this.type,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.downloadable,
  });

  factory AnthropicFileDescriptor.fromJson(Map<String, Object?> json) {
    return AnthropicFileDescriptor(
      id: anthropicRequiredNonEmptyString(json['id'], path: 'file.id'),
      type: anthropicOptionalString(json['type'], path: 'file.type') ?? 'file',
      filename: anthropicRequiredNonEmptyString(
        json['filename'],
        path: 'file.filename',
      ),
      mimeType: anthropicRequiredNonEmptyString(
        json['mime_type'],
        path: 'file.mime_type',
      ),
      sizeBytes:
          anthropicRequiredInt(json['size_bytes'], path: 'file.size_bytes'),
      createdAt: DateTime.parse(
        anthropicRequiredNonEmptyString(
          json['created_at'],
          path: 'file.created_at',
        ),
      ),
      downloadable: anthropicOptionalBool(
            json['downloadable'],
            path: 'file.downloadable',
          ) ??
          false,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'type': type,
      'filename': filename,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toIso8601String(),
      'downloadable': downloadable,
    };
  }
}

final class AnthropicFileListResponse {
  final List<AnthropicFileDescriptor> data;
  final bool hasMore;
  final String? firstId;
  final String? lastId;

  const AnthropicFileListResponse({
    required this.data,
    this.hasMore = false,
    this.firstId,
    this.lastId,
  });

  factory AnthropicFileListResponse.fromJson(Map<String, Object?> json) {
    return AnthropicFileListResponse(
      data: anthropicRequiredList(json['data'], path: 'file_list.data')
          .asMap()
          .entries
          .map((entry) {
        return AnthropicFileDescriptor.fromJson(
          anthropicRequiredMap(
            entry.value,
            path: 'file_list.data[${entry.key}]',
          ),
        );
      }).toList(growable: false),
      hasMore: anthropicOptionalBool(
            json['has_more'],
            path: 'file_list.has_more',
          ) ??
          false,
      firstId:
          anthropicOptionalString(json['first_id'], path: 'file_list.first_id'),
      lastId:
          anthropicOptionalString(json['last_id'], path: 'file_list.last_id'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'data': data.map((file) => file.toJson()).toList(growable: false),
      'has_more': hasMore,
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
    };
  }
}

final class AnthropicFileDeleteResponse {
  final String id;
  final bool deleted;

  const AnthropicFileDeleteResponse({
    required this.id,
    required this.deleted,
  });

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'deleted': deleted,
    };
  }
}

final class AnthropicFileDownload {
  final String fileId;
  final Uint8List bytes;
  final Map<String, String> headers;

  const AnthropicFileDownload({
    required this.fileId,
    required this.bytes,
    this.headers = const {},
  });

  String? get contentType => anthropicLookupHeader(headers, 'content-type');

  int get sizeBytes => bytes.length;
}
