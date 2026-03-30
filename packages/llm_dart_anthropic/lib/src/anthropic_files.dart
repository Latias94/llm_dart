import 'dart:typed_data';

import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_code_execution_replay.dart';
import 'anthropic_options.dart';

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

  Uri fileUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${_requireNonEmptyFileId(fileId)}',
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

extension AnthropicExecutionFileHandleFilesX on AnthropicExecutionFileHandle {
  Future<AnthropicFileDescriptor> getMetadata(
    AnthropicFiles files, {
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return files.getFile(
      fileId,
      timeout: timeout,
      cancellation: cancellation,
      headers: headers,
    );
  }

  Future<AnthropicFileDownload> download(
    AnthropicFiles files, {
    Duration? timeout,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) {
    return files.downloadFile(
      fileId,
      timeout: timeout,
      cancellation: cancellation,
      headers: headers,
    );
  }
}

String _requireNonEmptyFileId(String fileId) {
  if (fileId.isEmpty) {
    throw ArgumentError.value(
        fileId, 'fileId', 'Expected a non-empty file ID.');
  }

  return fileId;
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
