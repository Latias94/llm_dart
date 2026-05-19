import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_file_types.dart';
import 'anthropic_options.dart';

final class AnthropicFilesTransportSupport {
  static const String filesApiBetaFeature = 'files-api-2025-04-14';

  final String apiKey;
  final String baseUrl;
  final AnthropicFilesSettings settings;

  const AnthropicFilesTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.settings,
  });

  Uri get filesUri => resolveAnthropicUri(baseUrl, 'files');

  Uri fileListUri({
    String? beforeId,
    String? afterId,
    int? limit,
  }) {
    return _uriWithQuery(
      filesUri,
      _buildListQueryParameters(
        beforeId: beforeId,
        afterId: afterId,
        limit: limit,
      ),
    );
  }

  Uri fileUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${requireFileId(fileId, parameterName: 'fileId')}',
    );
  }

  Uri fileContentUri(String fileId) {
    return resolveAnthropicUri(
      baseUrl,
      'files/${requireFileId(fileId, parameterName: 'fileId')}/content',
    );
  }

  TransportRequest uploadRequest({
    required AnthropicFileUpload request,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    validateUpload(request);

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

    return TransportRequest(
      uri: filesUri,
      method: TransportMethod.post,
      headers: buildHeaders(
        extraHeaders: {
          'content-type': multipart.contentType,
          if (extraHeaders != null) ...extraHeaders,
        },
        accept: 'application/json',
      ),
      body: multipart.bytes,
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.json,
    );
  }

  TransportRequest jsonRequest({
    required Uri uri,
    required TransportMethod method,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    return TransportRequest(
      uri: uri,
      method: method,
      headers: buildHeaders(
        extraHeaders: extraHeaders,
        accept: 'application/json',
      ),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.json,
    );
  }

  TransportRequest bytesRequest({
    required Uri uri,
    required TransportMethod method,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    return TransportRequest(
      uri: uri,
      method: method,
      headers: buildHeaders(extraHeaders: extraHeaders),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.bytes,
    );
  }

  TransportRequest deleteRequest({
    required Uri uri,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    return TransportRequest(
      uri: uri,
      method: TransportMethod.delete,
      headers: buildHeaders(
        extraHeaders: extraHeaders,
        accept: 'application/json',
      ),
      timeout: timeout,
      maxRetries: maxRetries,
      cancellation: cancellation,
      responseType: TransportResponseType.plainText,
    );
  }

  Map<String, String> buildHeaders({
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

  void validateUpload(AnthropicFileUpload request) {
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

  String requireFileId(
    String fileId, {
    required String parameterName,
  }) {
    final normalized = fileId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        fileId,
        parameterName,
        'Expected a non-empty file ID.',
      );
    }

    return normalized;
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

Uri _uriWithQuery(Uri uri, Map<String, String> queryParameters) {
  if (queryParameters.isEmpty) {
    return uri;
  }
  return uri.replace(queryParameters: queryParameters);
}
