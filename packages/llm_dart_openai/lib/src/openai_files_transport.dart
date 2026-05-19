import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'openai_family_profile.dart';
import 'openai_files_options.dart';
import 'openai_non_text_model_support.dart';

final class OpenAIFilesTransportSupport {
  final String apiKey;
  final String baseUrl;
  final OpenAIFamilyProfile profile;
  final OpenAIFilesSettings settings;

  const OpenAIFilesTransportSupport({
    required this.apiKey,
    required this.baseUrl,
    required this.profile,
    required this.settings,
  });

  Uri get filesUri => Uri.parse('$baseUrl/files');

  Uri fileListUri({
    String? purpose,
    int? limit,
    String? order,
    String? after,
  }) {
    return _uriWithQuery(
      filesUri,
      _buildListQueryParameters(
        purpose: purpose,
        limit: limit,
        order: order,
        after: after,
      ),
    );
  }

  Uri fileUri(String fileId) {
    return Uri.parse(
      '$baseUrl/files/${Uri.encodeComponent(requireFileId(
        fileId,
        parameterName: 'fileId',
      ))}',
    );
  }

  Uri fileContentUri(String fileId) {
    return Uri.parse(
      '$baseUrl/files/${Uri.encodeComponent(requireFileId(
        fileId,
        parameterName: 'fileId',
      ))}/content',
    );
  }

  TransportRequest uploadRequest({
    required OpenAIFileUpload request,
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
        TransportMultipartField.text(
          name: 'purpose',
          value: request.purpose,
        ),
        if (request.expiresAfter != null)
          TransportMultipartField.text(
            name: 'expires_after',
            value: '${request.expiresAfter}',
          ),
      ],
    );

    return TransportRequest(
      uri: filesUri,
      method: TransportMethod.post,
      headers: buildHeaders(
        contentType: multipart.contentType,
        accept: 'application/json',
        extraHeaders: extraHeaders,
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
        accept: 'application/json',
        extraHeaders: extraHeaders,
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

  Map<String, String> buildHeaders({
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

  void validateUpload(OpenAIFileUpload request) {
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

    if (request.expiresAfter != null && request.expiresAfter! < 1) {
      throw ArgumentError.value(
        request.expiresAfter,
        'request.expiresAfter',
        'OpenAI file upload expiresAfter must be >= 1.',
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
        'Expected a non-empty OpenAI file ID.',
      );
    }

    return normalized;
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

Uri _uriWithQuery(Uri uri, Map<String, String> queryParameters) {
  if (queryParameters.isEmpty) {
    return uri;
  }
  return uri.replace(queryParameters: queryParameters);
}
