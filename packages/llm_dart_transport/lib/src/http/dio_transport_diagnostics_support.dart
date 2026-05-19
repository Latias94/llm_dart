import '../common/transport_diagnostics.dart';
import '../common/transport_exception.dart';
import '../common/transport_retry.dart';
import 'log_sanitizer.dart';
import 'transport_client.dart';

final class DioTransportDiagnosticsSupport {
  final TransportDiagnostics? diagnostics;
  final TransportDiagnosticsOptions options;

  const DioTransportDiagnosticsSupport({
    required this.diagnostics,
    required this.options,
  });

  TransportDiagnosticsRequestInfo createRequestInfo(
    TransportRequest request, {
    required bool isStreaming,
    required TransportRetryPolicy retryPolicy,
  }) {
    final headerNames = request.headers.keys.toList(growable: false)..sort();
    return TransportDiagnosticsRequestInfo(
      uri: request.uri,
      method: request.method,
      responseType: request.responseType,
      timeout: request.timeout,
      maxRetries: retryPolicy.maxRetries,
      isStreaming: isStreaming,
      hasBody: request.body != null,
      bodyType: request.body?.runtimeType.toString(),
      headerNames: headerNames,
      headers:
          options.includeHeaders ? _sanitizeHeaders(request.headers) : null,
      body: options.includeRequestBody
          ? options.sanitizeBody(request.body)
          : null,
    );
  }

  TransportDiagnosticsResponseInfo createResponseInfo({
    required int statusCode,
    required Map<String, String> headers,
    required Object? body,
    bool includeBody = true,
  }) {
    final headerNames = headers.keys.toList(growable: false)..sort();
    return TransportDiagnosticsResponseInfo(
      statusCode: statusCode,
      headerNames: headerNames,
      bodyType: body?.runtimeType.toString(),
      headers: options.includeHeaders ? _sanitizeHeaders(headers) : null,
      body: includeBody && options.includeResponseBody
          ? options.sanitizeBody(body)
          : null,
    );
  }

  TransportDiagnosticsResponseInfo? responseInfoFromError(Object error) {
    if (error is! TransportHttpException) {
      return null;
    }

    return createResponseInfo(
      statusCode: error.statusCode,
      headers: error.headers,
      body: error.responseBody,
    );
  }

  void emit(TransportDiagnosticsEvent event) {
    diagnostics?.onEvent(event);
  }

  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = LogSanitizer.sanitizeHeaders(headers);
    return sanitized.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
  }
}
