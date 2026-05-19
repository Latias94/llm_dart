import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_code_execution_replay.dart';
import 'anthropic_file_response.dart';
import 'anthropic_file_types.dart';
import 'anthropic_files_transport.dart';
import 'anthropic_model_settings.dart';

final class AnthropicFiles {
  final String apiKey;
  final String baseUrl;
  final TransportClient transport;
  final AnthropicFilesSettings settings;

  late final AnthropicFilesTransportSupport _requestSupport =
      AnthropicFilesTransportSupport(
    apiKey: apiKey,
    baseUrl: baseUrl,
    settings: settings,
  );

  AnthropicFiles({
    required this.apiKey,
    required this.transport,
    String? baseUrl,
    this.settings = const AnthropicFilesSettings(),
  }) : baseUrl = baseUrl ?? anthropicDefaultBaseUrl;

  Uri get filesUri => _requestSupport.filesUri;

  Uri fileUri(String fileId) {
    return _requestSupport.fileUri(fileId);
  }

  Future<AnthropicFileDescriptor> uploadFile(
    AnthropicFileUpload request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      _requestSupport.uploadRequest(
        request: request,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
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
    final response = await transport.send(
      _requestSupport.jsonRequest(
        uri: _requestSupport.fileListUri(
          beforeId: beforeId,
          afterId: afterId,
          limit: limit,
        ),
        method: TransportMethod.get,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
    );

    return decodeAnthropicFileListResponse(response.body);
  }

  Uri fileContentUri(String fileId) {
    return _requestSupport.fileContentUri(fileId);
  }

  Future<AnthropicFileDescriptor> getFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    final response = await transport.send(
      _requestSupport.jsonRequest(
        uri: fileUri(fileId),
        method: TransportMethod.get,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
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
    final normalizedFileId = _requestSupport.requireFileId(
      fileId,
      parameterName: 'fileId',
    );
    final response = await transport.send(
      _requestSupport.bytesRequest(
        uri: fileContentUri(normalizedFileId),
        method: TransportMethod.get,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
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
    final normalizedFileId = _requestSupport.requireFileId(
      fileId,
      parameterName: 'fileId',
    );
    await transport.send(
      _requestSupport.deleteRequest(
        uri: fileUri(normalizedFileId),
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
    );

    return AnthropicFileDeleteResponse(
      id: normalizedFileId,
      deleted: true,
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
