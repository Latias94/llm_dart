import 'dart:convert';
import 'dart:typed_data';

import 'openai_json_value.dart';

final class OpenAIFileObject {
  final String id;
  final String object;
  final int sizeBytes;
  final DateTime createdAt;
  final String filename;
  final String purpose;
  final String? status;
  final String? statusDetails;
  final DateTime? expiresAt;

  const OpenAIFileObject({
    required this.id,
    required this.object,
    required this.sizeBytes,
    required this.createdAt,
    required this.filename,
    required this.purpose,
    this.status,
    this.statusDetails,
    this.expiresAt,
  });

  factory OpenAIFileObject.fromJson(Map<String, Object?> json) {
    return OpenAIFileObject(
      id: openAIRequiredNonEmptyString(json['id'], path: 'file.id'),
      object:
          openAIOptionalString(json['object'], path: 'file.object') ?? 'file',
      sizeBytes: openAIRequiredInt(json['bytes'], path: 'file.bytes'),
      createdAt: openAIRequiredEpochSecondsDateTime(
        json['created_at'],
        path: 'file.created_at',
      ),
      filename: openAIRequiredNonEmptyString(
        json['filename'],
        path: 'file.filename',
      ),
      purpose:
          openAIRequiredNonEmptyString(json['purpose'], path: 'file.purpose'),
      status: openAIOptionalString(json['status'], path: 'file.status'),
      statusDetails: openAIOptionalString(
        json['status_details'],
        path: 'file.status_details',
      ),
      expiresAt: openAIOptionalEpochSecondsDateTime(
        json['expires_at'],
        path: 'file.expires_at',
      ),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'object': object,
      'bytes': sizeBytes,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'filename': filename,
      'purpose': purpose,
      if (status != null) 'status': status,
      if (statusDetails != null) 'status_details': statusDetails,
      if (expiresAt != null)
        'expires_at': expiresAt!.millisecondsSinceEpoch ~/ 1000,
    };
  }
}

final class OpenAIFileListResponse {
  final String object;
  final List<OpenAIFileObject> data;
  final String? firstId;
  final String? lastId;
  final bool? hasMore;

  const OpenAIFileListResponse({
    required this.data,
    this.object = 'list',
    this.firstId,
    this.lastId,
    this.hasMore,
  });

  factory OpenAIFileListResponse.fromJson(Map<String, Object?> json) {
    return OpenAIFileListResponse(
      object: openAIOptionalString(json['object'], path: 'file_list.object') ??
          'list',
      data: openAIRequiredList(json['data'], path: 'file_list.data')
          .asMap()
          .entries
          .map((entry) {
        return OpenAIFileObject.fromJson(
          openAIRequiredMap(
            entry.value,
            path: 'file_list.data[${entry.key}]',
          ),
        );
      }).toList(growable: false),
      firstId:
          openAIOptionalString(json['first_id'], path: 'file_list.first_id'),
      lastId: openAIOptionalString(json['last_id'], path: 'file_list.last_id'),
      hasMore: openAIOptionalBool(json['has_more'], path: 'file_list.has_more'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'object': object,
      'data': data.map((file) => file.toJson()).toList(growable: false),
      if (firstId != null) 'first_id': firstId,
      if (lastId != null) 'last_id': lastId,
      if (hasMore != null) 'has_more': hasMore,
    };
  }
}

final class OpenAIFileDeleteResponse {
  final String id;
  final String object;
  final bool deleted;

  const OpenAIFileDeleteResponse({
    required this.id,
    required this.deleted,
    this.object = 'file',
  });

  factory OpenAIFileDeleteResponse.fromJson(Map<String, Object?> json) {
    return OpenAIFileDeleteResponse(
      id: openAIRequiredNonEmptyString(json['id'], path: 'file_delete.id'),
      object:
          openAIOptionalString(json['object'], path: 'file_delete.object') ??
              'file',
      deleted: openAIRequiredBool(json['deleted'], path: 'file_delete.deleted'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'object': object,
      'deleted': deleted,
    };
  }
}

final class OpenAIFileDownload {
  final String fileId;
  final Uint8List bytes;
  final Map<String, String> headers;

  const OpenAIFileDownload({
    required this.fileId,
    required this.bytes,
    this.headers = const {},
  });

  String? get contentType => openAILookupHeader(headers, 'content-type');

  int get sizeBytes => bytes.length;

  String text({Encoding encoding = utf8}) {
    return encoding.decode(bytes);
  }
}
