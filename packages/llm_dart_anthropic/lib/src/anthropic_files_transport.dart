import 'package:llm_dart_transport/llm_dart_transport.dart';

import 'anthropic_api.dart';
import 'anthropic_files_route_support.dart';
import 'anthropic_model_settings.dart';

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

  AnthropicFilesRouteSupport get _routes =>
      AnthropicFilesRouteSupport(baseUrl: baseUrl);

  Uri get filesUri => _routes.filesUri;

  Uri fileListUri({
    String? beforeId,
    String? afterId,
    int? limit,
  }) {
    return _routes.fileListUri(
      beforeId: beforeId,
      afterId: afterId,
      limit: limit,
    );
  }

  Uri fileUri(String fileId) => _routes.fileUri(fileId);

  Uri fileContentUri(String fileId) => _routes.fileContentUri(fileId);

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
        extraHeaders: {
          'content-type': body.contentType,
          if (extraHeaders != null) ...extraHeaders,
        },
        accept: 'application/json',
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

  String requireFileId(
    String fileId, {
    required String parameterName,
  }) {
    return _routes.requireFileId(fileId, parameterName: parameterName);
  }
}
