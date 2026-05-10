import '../http/transport_client.dart';

typedef TransportDiagnosticsBodySanitizer = Object? Function(Object? body);

enum TransportDiagnosticsEventKind {
  requestStart,
  requestSuccess,
  requestFailure,
}

final class TransportDiagnosticsOptions {
  final bool includeHeaders;
  final bool includeRequestBody;
  final bool includeResponseBody;
  final TransportDiagnosticsBodySanitizer? bodySanitizer;

  const TransportDiagnosticsOptions({
    this.includeHeaders = false,
    this.includeRequestBody = false,
    this.includeResponseBody = false,
    this.bodySanitizer,
  });

  Object? sanitizeBody(Object? body) {
    return bodySanitizer?.call(body) ?? body;
  }
}

final class TransportDiagnosticsRequestInfo {
  final Uri uri;
  final TransportMethod method;
  final TransportResponseType responseType;
  final Duration? timeout;
  final int? maxRetries;
  final bool isStreaming;
  final bool hasBody;
  final String? bodyType;
  final List<String> headerNames;
  final Map<String, String>? headers;
  final Object? body;

  TransportDiagnosticsRequestInfo({
    required this.uri,
    required this.method,
    required this.responseType,
    required this.isStreaming,
    required List<String> headerNames,
    this.timeout,
    this.maxRetries,
    this.hasBody = false,
    this.bodyType,
    Map<String, String>? headers,
    this.body,
  })  : headerNames = List<String>.unmodifiable(headerNames),
        headers =
            headers == null ? null : Map<String, String>.unmodifiable(headers);
}

final class TransportDiagnosticsResponseInfo {
  final int statusCode;
  final List<String> headerNames;
  final String? bodyType;
  final Map<String, String>? headers;
  final Object? body;

  TransportDiagnosticsResponseInfo({
    required this.statusCode,
    required List<String> headerNames,
    this.bodyType,
    Map<String, String>? headers,
    this.body,
  })  : headerNames = List<String>.unmodifiable(headerNames),
        headers =
            headers == null ? null : Map<String, String>.unmodifiable(headers);
}

final class TransportDiagnosticsEvent {
  final TransportDiagnosticsEventKind kind;
  final TransportDiagnosticsRequestInfo request;
  final TransportDiagnosticsResponseInfo? response;
  final Object? error;
  final DateTime timestamp;
  final Duration? duration;
  final int attempt;

  const TransportDiagnosticsEvent({
    required this.kind,
    required this.request,
    required this.timestamp,
    this.response,
    this.error,
    this.duration,
    this.attempt = 1,
  });
}

abstract interface class TransportDiagnostics {
  void onEvent(TransportDiagnosticsEvent event);
}

final class CallbackTransportDiagnostics implements TransportDiagnostics {
  final void Function(TransportDiagnosticsEvent event) callback;

  const CallbackTransportDiagnostics(this.callback);

  @override
  void onEvent(TransportDiagnosticsEvent event) {
    callback(event);
  }
}
