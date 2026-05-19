import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_family_url_support.dart';
import 'openai_files_models.dart';
import 'openai_files_options.dart';
import 'openai_files_transport.dart';
import 'openai_json_support.dart';
import 'openai_json_value.dart';
import 'openai_profile_boundary.dart';

export 'openai_files_models.dart'
    show
        OpenAIFileDeleteResponse,
        OpenAIFileDownload,
        OpenAIFileListResponse,
        OpenAIFileObject;
export 'openai_files_options.dart'
    show OpenAIFilePurposes, OpenAIFileUpload, OpenAIFilesSettings;

final class OpenAIFilesClient {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final TransportClient transport;
  final OpenAIFilesSettings settings;

  late final OpenAIFilesTransportSupport _requestSupport =
      OpenAIFilesTransportSupport(
    apiKey: apiKey,
    baseUrl: baseUrl,
    profile: profile,
    settings: settings,
  );

  OpenAIFilesClient({
    required this.apiKey,
    required this.profile,
    required this.transport,
    this.settings = const OpenAIFilesSettings(),
    String? baseUrl,
  }) : baseUrl = normalizeOpenAIFamilyBaseUrl(baseUrl, profile) {
    requireOpenAIProfile(profile, featureName: 'OpenAI files client');
  }

  Uri get filesUri => _requestSupport.filesUri;

  Uri fileUri(String fileId) {
    return _requestSupport.fileUri(fileId);
  }

  Uri fileContentUri(String fileId) {
    return _requestSupport.fileContentUri(fileId);
  }

  Future<T> _sendJsonRequest<T>({
    required TransportRequest request,
    required String responseName,
    required T Function(Map<String, Object?> json) decode,
  }) async {
    final response = await transport.send(request);
    return decode(
      decodeOpenAIJsonObject(response.body, responseName: responseName),
    );
  }

  Future<OpenAIFileObject> uploadFile(
    OpenAIFileUpload request, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonRequest(
      request: _requestSupport.uploadRequest(
        request: request,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
      responseName: 'file upload response',
      decode: (json) => OpenAIFileObject.fromJson(json),
    );
  }

  Future<OpenAIFileObject> uploadBytes({
    required List<int> bytes,
    required String filename,
    String purpose = OpenAIFilePurposes.assistants,
    String mediaType = 'application/octet-stream',
    int? expiresAfter,
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
        expiresAfter: expiresAfter,
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
    return _sendJsonRequest(
      request: _requestSupport.jsonRequest(
        uri: _requestSupport.fileListUri(
          purpose: purpose,
          limit: limit,
          order: order,
          after: after,
        ),
        method: TransportMethod.get,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
      responseName: 'file list response',
      decode: (json) => OpenAIFileListResponse.fromJson(json),
    );
  }

  Future<OpenAIFileObject> retrieveFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonRequest(
      request: _requestSupport.jsonRequest(
        uri: fileUri(fileId),
        method: TransportMethod.get,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
      responseName: 'file response',
      decode: (json) => OpenAIFileObject.fromJson(json),
    );
  }

  Future<OpenAIFileDeleteResponse> deleteFile(
    String fileId, {
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? headers,
  }) async {
    return _sendJsonRequest(
      request: _requestSupport.jsonRequest(
        uri: fileUri(fileId),
        method: TransportMethod.delete,
        timeout: timeout,
        maxRetries: maxRetries,
        cancellation: cancellation,
        extraHeaders: headers,
      ),
      responseName: 'file delete response',
      decode: (json) => OpenAIFileDeleteResponse.fromJson(json),
    );
  }

  Future<OpenAIFileDownload> downloadFile(
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

    return OpenAIFileDownload(
      fileId: normalizedFileId,
      bytes: openAIRequiredBytes(
        response.body,
        path: 'file_download.body',
        sourceName: 'OpenAI file download',
      ),
      headers: response.headers,
    );
  }
}
