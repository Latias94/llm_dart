import '../common/transport_cancellation.dart';

enum TransportMethod {
  get,
  post,
  put,
  patch,
  delete,
}

final class TransportRequest {
  final Uri uri;
  final TransportMethod method;
  final Map<String, String> headers;
  final Object? body;
  final Duration? timeout;
  final TransportCancellation? cancellation;

  const TransportRequest({
    required this.uri,
    required this.method,
    this.headers = const {},
    this.body,
    this.timeout,
    this.cancellation,
  });
}

final class TransportResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Object? body;

  const TransportResponse({
    required this.statusCode,
    this.headers = const {},
    this.body,
  });
}

final class StreamingTransportResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Stream<List<int>> stream;

  const StreamingTransportResponse({
    required this.statusCode,
    required this.stream,
    this.headers = const {},
  });
}

abstract interface class TransportClient {
  Future<TransportResponse> send(TransportRequest request);

  Future<StreamingTransportResponse> sendStream(TransportRequest request);
}
