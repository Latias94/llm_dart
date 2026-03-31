import '../http/transport_client.dart';

enum TransportDiagnosticsEventKind {
  requestStart,
  requestSuccess,
  requestFailure,
}

final class TransportDiagnosticsRequestInfo {
  final Uri uri;
  final TransportMethod method;
  final TransportResponseType responseType;
  final Duration? timeout;
  final bool isStreaming;
  final bool hasBody;
  final String? bodyType;
  final List<String> headerNames;

  TransportDiagnosticsRequestInfo({
    required this.uri,
    required this.method,
    required this.responseType,
    required this.isStreaming,
    required List<String> headerNames,
    this.timeout,
    this.hasBody = false,
    this.bodyType,
  }) : headerNames = List<String>.unmodifiable(headerNames);
}

final class TransportDiagnosticsResponseInfo {
  final int statusCode;
  final List<String> headerNames;
  final String? bodyType;

  TransportDiagnosticsResponseInfo({
    required this.statusCode,
    required List<String> headerNames,
    this.bodyType,
  }) : headerNames = List<String>.unmodifiable(headerNames);
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
