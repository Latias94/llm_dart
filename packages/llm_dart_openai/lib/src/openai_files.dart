import 'dart:convert';
import 'dart:typed_data';

import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_json_support.dart';
import 'openai_non_text_model_support.dart';
import 'openai_profile_boundary.dart';

abstract final class OpenAIFilePurposes {
  static const String assistants = 'assistants';
  static const String batch = 'batch';
  static const String fineTune = 'fine-tune';
  static const String userData = 'user_data';
  static const String vision = 'vision';
}

final class OpenAIFilesSettings {
  final String? organization;
  final String? project;
  final Map<String, String> headers;

  const OpenAIFilesSettings({
    this.organization,
    this.project,
    this.headers = const {},
  });
}

final class OpenAIFileUpload {
  final List<int> bytes;
  final String filename;
  final String purpose;
  final String mediaType;

  const OpenAIFileUpload({
    required this.bytes,
    required this.filename,
    required this.purpose,
    this.mediaType = 'application/octet-stream',
  });
}

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
      id: _requiredNonEmptyString(json['id'], path: 'file.id'),
      object: _optionalString(json['object'], path: 'file.object') ?? 'file',
      sizeBytes: _requiredInt(json['bytes'], path: 'file.bytes'),
      createdAt: _requiredEpochSecondsDateTime(
        json['created_at'],
        path: 'file.created_at',
      ),
      filename: _requiredNonEmptyString(
        json['filename'],
        path: 'file.filename',
      ),
      purpose: _requiredNonEmptyString(json['purpose'], path: 'file.purpose'),
      status: _optionalString(json['status'], path: 'file.status'),
      statusDetails: _optionalString(
        json['status_details'],
        path: 'file.status_details',
      ),
      expiresAt: _optionalEpochSecondsDateTime(
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
      object:
          _optionalString(json['object'], path: 'file_list.object') ?? 'list',
      data: _requiredList(json['data'], path: 'file_list.data')
          .asMap()
          .entries
          .map((entry) {
        return OpenAIFileObject.fromJson(
          _requiredMap(
            entry.value,
            path: 'file_list.data[${entry.key}]',
          ),
        );
      }).toList(growable: false),
      firstId: _optionalString(json['first_id'], path: 'file_list.first_id'),
      lastId: _optionalString(json['last_id'], path: 'file_list.last_id'),
      hasMore: _optionalBool(json['has_more'], path: 'file_list.has_more'),
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
      id: _requiredNonEmptyString(json['id'], path: 'file_delete.id'),
      object:
          _optionalString(json['object'], path: 'file_delete.object') ?? 'file',
      deleted: _requiredBool(json['deleted'], path: 'file_delete.deleted'),
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

  String? get contentType => _lookupHeader(headers, 'content-type');

  int get sizeBytes => bytes.length;

  String text({Encoding encoding = utf8}) {
    return encoding.decode(bytes);
  }
}

final class OpenAIFilesClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIFilesSettings settings;

  OpenAIFilesClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIFilesSettings(),
    String? baseUrl,
  }) : baseUrl = baseUrl ?? profile.defaultBaseUrl {
    requireOpenAIProfile(profile, featureName: 'OpenAI files client');
  }

  Uri get filesUri => Uri.parse('$baseUrl/files');

  Uri fileUri(String fileId) {
    return Uri.parse(
      '$baseUrl/files/${Uri.encodeComponent(_requireNonEmptyFileId(fileId))}',
    );
  }

  Uri fileContentUri(String fileId) {
    return Uri.parse(
      '$baseUrl/files/${Uri.encodeComponent(_requireNonEmptyFileId(fileId))}/content',
    );
  }

  Future<OpenAIFileObject> uploadFile(
    OpenAIFileUpload request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    _validateUpload(request);

    final multipart = buildTransportMultipartBody(
      fields: [
        TransportMultipartField.file(
          name: 'file',
          filename: request.filename,
          mediaType: request.mediaType,
          bytes: request.bytes,
        ),
        TransportMultipartField.text(
          name: 'purpose',
          value: request.purpose,
        ),
      ],
    );

    final response = await transport.send(
      TransportRequest(
        uri: filesUri,
        method: TransportMethod.post,
        headers: _buildHeaders(
          contentType: multipart.contentType,
          accept: 'application/json',
          extraHeaders: headers,
        ),
        body: multipart.bytes,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIFileObject.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'file upload response',
      ),
    );
  }

  Future<OpenAIFileObject> uploadBytes({
    required List<int> bytes,
    required String filename,
    required String purpose,
    String mediaType = 'application/octet-stream',
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return uploadFile(
      OpenAIFileUpload(
        bytes: bytes,
        filename: filename,
        purpose: purpose,
        mediaType: mediaType,
      ),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<OpenAIFileListResponse> listFiles({
    String? purpose,
    int? limit,
    String? order,
    String? after,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final queryParameters = _buildListQueryParameters(
      purpose: purpose,
      limit: limit,
      order: order,
      after: after,
    );
    final uri = queryParameters.isEmpty
        ? filesUri
        : filesUri.replace(queryParameters: queryParameters);

    final response = await transport.send(
      TransportRequest(
        uri: uri,
        method: TransportMethod.get,
        headers: _buildHeaders(
          accept: 'application/json',
          extraHeaders: headers,
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIFileListResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'file list response',
      ),
    );
  }

  Future<OpenAIFileObject> retrieveFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: fileUri(fileId),
        method: TransportMethod.get,
        headers: _buildHeaders(
          accept: 'application/json',
          extraHeaders: headers,
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIFileObject.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'file response',
      ),
    );
  }

  Future<OpenAIFileDeleteResponse> deleteFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      TransportRequest(
        uri: fileUri(fileId),
        method: TransportMethod.delete,
        headers: _buildHeaders(
          accept: 'application/json',
          extraHeaders: headers,
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return OpenAIFileDeleteResponse.fromJson(
      decodeOpenAIJsonObject(
        response.body,
        responseName: 'file delete response',
      ),
    );
  }

  Future<OpenAIFileDownload> downloadFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final normalizedFileId = _requireNonEmptyFileId(fileId);
    final response = await transport.send(
      TransportRequest(
        uri: fileContentUri(normalizedFileId),
        method: TransportMethod.get,
        headers: _buildHeaders(
          extraHeaders: headers,
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.bytes,
      ),
    );

    return OpenAIFileDownload(
      fileId: normalizedFileId,
      bytes: _decodeBytes(response.body, path: 'file_download.body'),
      headers: response.headers,
    );
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
    String? contentType,
    String? accept,
  }) {
    return buildOpenAIFamilyDefaultHeaders(
      profile: profile,
      apiKey: apiKey,
      organization: settings.organization,
      project: settings.project,
      headers: {
        ...settings.headers,
        if (contentType != null) 'content-type': contentType,
        if (accept != null) 'accept': accept,
        if (extraHeaders != null) ...extraHeaders,
      },
    );
  }
}

Map<String, String> _buildListQueryParameters({
  String? purpose,
  int? limit,
  String? order,
  String? after,
}) {
  if (limit != null && limit < 1) {
    throw ArgumentError.value(
      limit,
      'limit',
      'OpenAI file list limit must be >= 1.',
    );
  }

  return {
    if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
    if (limit != null) 'limit': '$limit',
    if (order != null && order.isNotEmpty) 'order': order,
    if (after != null && after.isNotEmpty) 'after': after,
  };
}

void _validateUpload(OpenAIFileUpload request) {
  if (request.bytes.isEmpty) {
    throw ArgumentError.value(
      request.bytes,
      'request.bytes',
      'OpenAI file uploads require non-empty bytes.',
    );
  }

  if (request.filename.trim().isEmpty) {
    throw ArgumentError.value(
      request.filename,
      'request.filename',
      'OpenAI file uploads require a non-empty filename.',
    );
  }

  if (request.purpose.trim().isEmpty) {
    throw ArgumentError.value(
      request.purpose,
      'request.purpose',
      'OpenAI file uploads require a non-empty purpose.',
    );
  }

  if (request.mediaType.trim().isEmpty) {
    throw ArgumentError.value(
      request.mediaType,
      'request.mediaType',
      'OpenAI file uploads require a non-empty media type.',
    );
  }
}

String _requireNonEmptyFileId(String fileId) {
  final normalized = fileId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      fileId,
      'fileId',
      'Expected a non-empty OpenAI file ID.',
    );
  }

  return normalized;
}

Uint8List _decodeBytes(
  Object? body, {
  required String path,
}) {
  if (body is Uint8List) {
    return body;
  }

  if (body is List<int>) {
    return Uint8List.fromList(body);
  }

  if (body is List) {
    final bytes = <int>[];
    for (var index = 0; index < body.length; index += 1) {
      bytes.add(_requiredInt(body[index], path: '$path[$index]'));
    }
    return Uint8List.fromList(bytes);
  }

  throw StateError(
    'Expected OpenAI file download bytes at $path but received ${body.runtimeType}.',
  );
}

Map<String, Object?> _requiredMap(
  Object? value, {
  required String path,
}) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return Map<String, Object?>.from(value);
  }

  throw FormatException('Expected a JSON object at $path.');
}

List<Object?> _requiredList(
  Object? value, {
  required String path,
}) {
  if (value is List<Object?>) {
    return value;
  }

  if (value is List) {
    return List<Object?>.from(value);
  }

  throw FormatException('Expected a list at $path.');
}

String _requiredNonEmptyString(
  Object? value, {
  required String path,
}) {
  final normalized = _optionalString(value, path: path);
  if (normalized == null || normalized.isEmpty) {
    throw FormatException('Expected a non-empty string at $path.');
  }

  return normalized;
}

String? _optionalString(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected a string at $path.');
}

int _requiredInt(
  Object? value, {
  required String path,
}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Expected an int at $path.');
}

bool _requiredBool(
  Object? value, {
  required String path,
}) {
  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

bool? _optionalBool(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  if (value is bool) {
    return value;
  }

  throw FormatException('Expected a bool at $path.');
}

DateTime _requiredEpochSecondsDateTime(
  Object? value, {
  required String path,
}) {
  return DateTime.fromMillisecondsSinceEpoch(
    _requiredInt(value, path: path) * 1000,
    isUtc: true,
  );
}

DateTime? _optionalEpochSecondsDateTime(
  Object? value, {
  required String path,
}) {
  if (value == null) {
    return null;
  }

  return _requiredEpochSecondsDateTime(value, path: path);
}

String? _lookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
}
