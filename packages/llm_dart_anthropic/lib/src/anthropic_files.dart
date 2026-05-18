import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_code_execution_replay.dart';
import 'anthropic_file_response.dart';
import 'anthropic_file_types.dart';
import 'anthropic_options.dart';

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

    return decodeAnthropicFileDescriptorResponse(
      response.body,
      responseName: 'file upload',
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

    return decodeAnthropicFileListResponse(response.body);
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

    return decodeAnthropicFileDescriptorResponse(
      response.body,
      responseName: 'file metadata',
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

    return decodeAnthropicFileDownload(
      fileId: normalizedFileId,
      body: response.body,
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
