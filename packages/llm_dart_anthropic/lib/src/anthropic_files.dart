import 'dart:typed_data';

import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_code_execution_replay.dart';
import 'anthropic_options.dart';

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
      id: _requiredNonEmptyString(json['id'], path: 'file.id'),
      type: _optionalString(json['type'], path: 'file.type') ?? 'file',
      filename:
          _requiredNonEmptyString(json['filename'], path: 'file.filename'),
      mimeType: _requiredNonEmptyString(
        json['mime_type'],
        path: 'file.mime_type',
      ),
      sizeBytes: _requiredInt(json['size_bytes'], path: 'file.size_bytes'),
      createdAt: DateTime.parse(
        _requiredNonEmptyString(json['created_at'], path: 'file.created_at'),
      ),
      downloadable: _optionalBool(
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
      data: _requiredList(json['data'], path: 'file_list.data')
          .asMap()
          .entries
          .map((entry) {
        return AnthropicFileDescriptor.fromJson(
          _requiredMap(
            entry.value,
            path: 'file_list.data[${entry.key}]',
          ),
        );
      }).toList(growable: false),
      hasMore:
          _optionalBool(json['has_more'], path: 'file_list.has_more') ?? false,
      firstId: _optionalString(json['first_id'], path: 'file_list.first_id'),
      lastId: _optionalString(json['last_id'], path: 'file_list.last_id'),
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

  String? get contentType => _lookupHeader(headers, 'content-type');

  int get sizeBytes => bytes.length;
}

final class AnthropicFiles {
  static const String filesApiBetaFeature = 'files-api-2025-04-14';

  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final AnthropicFilesSettings settings;

  AnthropicFiles({
    required this.apiKey,
    required this.transport,
    String? baseUrl,
    this.settings = const AnthropicFilesSettings(),
  }) : baseUrl = baseUrl ?? anthropicDefaultBaseUrl;

  Uri get filesUri => resolveAnthropicUri(baseUrl, 'files');

  Uri fileUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${_requireNonEmptyFileId(fileId)}',
    );
  }

  Future<AnthropicFileDescriptor> uploadFile(
    AnthropicFileUpload request, {
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
      ],
    );

    final response = await transport.send(
      TransportRequest(
        uri: filesUri,
        method: TransportMethod.post,
        headers: _buildHeaders(
          extraHeaders: {
            'content-type': multipart.contentType,
            if (headers != null) ...headers,
          },
          accept: 'application/json',
        ),
        body: multipart.bytes,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return AnthropicFileDescriptor.fromJson(
      decodeAnthropicJsonObject(response.body),
    );
  }

  Future<AnthropicFileDescriptor> uploadBytes({
    required List<int> bytes,
    required String filename,
    String mediaType = 'application/octet-stream',
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return uploadFile(
      AnthropicFileUpload(
        bytes: bytes,
        filename: filename,
        mediaType: mediaType,
      ),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<AnthropicFileListResponse> listFiles({
    String? beforeId,
    String? afterId,
    int? limit,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final queryParameters = _buildListQueryParameters(
      beforeId: beforeId,
      afterId: afterId,
      limit: limit,
    );
    final uri = queryParameters.isEmpty
        ? filesUri
        : filesUri.replace(queryParameters: queryParameters);

    final response = await transport.send(
      TransportRequest(
        uri: uri,
        method: TransportMethod.get,
        headers: _buildHeaders(
          extraHeaders: headers,
          accept: 'application/json',
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return AnthropicFileListResponse.fromJson(
      decodeAnthropicJsonObject(response.body),
    );
  }

  Uri fileContentUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${_requireNonEmptyFileId(fileId)}/content',
    );
  }

  Future<AnthropicFileDescriptor> getFile(
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
          extraHeaders: headers,
          accept: 'application/json',
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.json,
      ),
    );

    return AnthropicFileDescriptor.fromJson(
      decodeAnthropicJsonObject(response.body),
    );
  }

  Future<AnthropicFileDownload> downloadFile(
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

    return AnthropicFileDownload(
      fileId: normalizedFileId,
      bytes: _decodeBytes(
        response.body,
        path: 'download.body',
      ),
      headers: response.headers,
    );
  }

  Future<AnthropicFileDeleteResponse> deleteFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final normalizedFileId = _requireNonEmptyFileId(fileId);
    await transport.send(
      TransportRequest(
        uri: fileUri(normalizedFileId),
        method: TransportMethod.delete,
        headers: _buildHeaders(
          extraHeaders: headers,
          accept: 'application/json',
        ),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        responseType: TransportResponseType.plainText,
      ),
    );

    return AnthropicFileDeleteResponse(
      id: normalizedFileId,
      deleted: true,
    );
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? extraHeaders,
    String? accept,
  }) {
    return buildAnthropicHeaders(
      apiKey: apiKey,
      anthropicVersion: settings.anthropicVersion,
      defaultHeaders: settings.headers,
      extraHeaders: extraHeaders,
      betaFeatures: [
        filesApiBetaFeature,
        ...settings.betaFeatures,
      ],
      accept: accept,
    );
  }
}

Map<String, String> _buildListQueryParameters({
  String? beforeId,
  String? afterId,
  int? limit,
}) {
  if (limit != null && limit < 1) {
    throw ArgumentError.value(
      limit,
      'limit',
      'Anthropic file list limit must be >= 1.',
    );
  }

  return {
    if (beforeId != null && beforeId.isNotEmpty) 'before_id': beforeId,
    if (afterId != null && afterId.isNotEmpty) 'after_id': afterId,
    if (limit != null) 'limit': '$limit',
  };
}

void _validateUpload(AnthropicFileUpload request) {
  if (request.bytes.isEmpty) {
    throw ArgumentError.value(
      request.bytes,
      'request.bytes',
      'Anthropic file uploads require non-empty bytes.',
    );
  }

  if (request.filename.trim().isEmpty) {
    throw ArgumentError.value(
      request.filename,
      'request.filename',
      'Anthropic file uploads require a non-empty filename.',
    );
  }

  if (request.mediaType.trim().isEmpty) {
    throw ArgumentError.value(
      request.mediaType,
      'request.mediaType',
      'Anthropic file uploads require a non-empty media type.',
    );
  }
}

extension AnthropicExecutionFileHandleFilesX on AnthropicExecutionFileHandle {
  Future<AnthropicFileDescriptor> getMetadata(
    AnthropicFiles files, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return files.getFile(
      fileId,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<AnthropicFileDownload> download(
    AnthropicFiles files, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return files.downloadFile(
      fileId,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      headers: headers,
    );
  }
}

String _requireNonEmptyFileId(String fileId) {
  final normalized = fileId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
        fileId, 'fileId', 'Expected a non-empty file ID.');
  }

  return normalized;
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
    for (var index = 0; index < body.length; index++) {
      bytes.add(
        _requiredInt(
          body[index],
          path: '$path[$index]',
        ),
      );
    }
    return Uint8List.fromList(bytes);
  }

  throw StateError(
    'Expected Anthropic file download bytes at $path but received ${body.runtimeType}.',
  );
}

String? _lookupHeader(Map<String, String> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) {
      return entry.value;
    }
  }

  return null;
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
