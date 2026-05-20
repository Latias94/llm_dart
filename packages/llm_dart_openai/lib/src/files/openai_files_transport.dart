import 'package:llm_dart_transport/llm_dart_transport.dart';

import '../provider/openai_family_profile.dart';
import 'openai_files_options.dart';
import '../common/openai_non_text_model_support.dart';

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
    required TransportMultipartBody body,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    Map<String, String>? extraHeaders,
  }) {
    return TransportRequest(
      uri: filesUri,
      method: TransportMethod.post,
      headers: buildHeaders(
        contentType: body.contentType,
        accept: 'application/json',
        extraHeaders: extraHeaders,
      ),
      body: body.bytes,
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
