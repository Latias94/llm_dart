import '../common/transport_cancellation.dart';

const Object _transportUnset = Object();

enum TransportMethod {
  get,
  post,
  put,
  patch,
  delete,
}

enum TransportResponseType {
  json,
  plainText,
  bytes,
}

final class TransportRequest {
  final Uri uri;
  final TransportMethod method;
  final Map<String, String> headers;
  final Object? body;
  final Duration? timeout;
  final int? maxRetries;
  final TransportCancellation? cancellation;
  final TransportResponseType responseType;

  const TransportRequest({
    required this.uri,
    required this.method,
    this.headers = const {},
    this.body,
    this.timeout,
    this.maxRetries,
    this.cancellation,
    this.responseType = TransportResponseType.json,
  }) : assert(maxRetries == null || maxRetries >= 0);

  TransportRequest copyWith({
    Uri? uri,
    TransportMethod? method,
    Map<String, String>? headers,
    Object? body = _transportUnset,
    Duration? timeout,
    int? maxRetries,
    TransportCancellation? cancellation,
    TransportResponseType? responseType,
  }) {
    return TransportRequest(
      uri: uri ?? this.uri,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      body: identical(body, _transportUnset) ? this.body : body,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      cancellation: cancellation ?? this.cancellation,
      responseType: responseType ?? this.responseType,
    );
  }
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

  TransportResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Object? body = _transportUnset,
  }) {
    return TransportResponse(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      body: identical(body, _transportUnset) ? this.body : body,
    );
  }
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

  StreamingTransportResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Stream<List<int>>? stream,
  }) {
    return StreamingTransportResponse(
      statusCode: statusCode ?? this.statusCode,
      headers: headers ?? this.headers,
      stream: stream ?? this.stream,
    );
  }
}

abstract interface class TransportClient {
  Future<TransportResponse> send(TransportRequest request);

  Future<StreamingTransportResponse> sendStream(TransportRequest request);
}
