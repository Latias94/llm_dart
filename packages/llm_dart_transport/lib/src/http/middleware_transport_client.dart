import 'dart:async';

import 'transport_client.dart';

typedef TransportRequestMiddleware = FutureOr<TransportRequest> Function(
  TransportRequest request,
);

typedef TransportResponseMiddleware = FutureOr<TransportResponse> Function(
  TransportRequest request,
  TransportResponse response,
);

typedef StreamingTransportResponseMiddleware
    = FutureOr<StreamingTransportResponse> Function(
  TransportRequest request,
  StreamingTransportResponse response,
);

typedef TransportErrorMiddleware = FutureOr<Object?> Function(
  TransportRequest request,
  Object error,
  StackTrace stackTrace,
);

final class TransportMiddleware {
  final TransportRequestMiddleware? onRequest;
  final TransportResponseMiddleware? onResponse;
  final StreamingTransportResponseMiddleware? onStreamResponse;
  final TransportErrorMiddleware? onError;

  const TransportMiddleware({
    this.onRequest,
    this.onResponse,
    this.onStreamResponse,
    this.onError,
  });
}

final class MiddlewareTransportClient implements TransportClient {
  final TransportClient inner;
  final List<TransportMiddleware> middlewares;

  MiddlewareTransportClient({
    required this.inner,
    Iterable<TransportMiddleware> middlewares = const [],
  }) : middlewares = List<TransportMiddleware>.unmodifiable(middlewares);

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    final effectiveRequest = await _applyRequest(request);
    try {
      var response = await inner.send(effectiveRequest);
      for (final middleware in middlewares.reversed) {
        final onResponse = middleware.onResponse;
        if (onResponse == null) continue;
        response = await onResponse(effectiveRequest, response);
      }
      return response;
    } catch (error, stackTrace) {
      return _handleError(effectiveRequest, error, stackTrace);
    }
  }

  @override
  Future<StreamingTransportResponse> sendStream(
      TransportRequest request) async {
    final effectiveRequest = await _applyRequest(request);
    try {
      var response = await inner.sendStream(effectiveRequest);
      for (final middleware in middlewares.reversed) {
        final onStreamResponse = middleware.onStreamResponse;
        if (onStreamResponse == null) continue;
        response = await onStreamResponse(effectiveRequest, response);
      }
      return response;
    } catch (error, stackTrace) {
      return _handleError(effectiveRequest, error, stackTrace);
    }
  }

  Future<TransportRequest> _applyRequest(TransportRequest request) async {
    var effectiveRequest = request;
    for (final middleware in middlewares) {
      final onRequest = middleware.onRequest;
      if (onRequest == null) continue;
      effectiveRequest = await onRequest(effectiveRequest);
    }
    return effectiveRequest;
  }

  Future<T> _handleError<T>(
    TransportRequest request,
    Object error,
    StackTrace stackTrace,
  ) async {
    var effectiveError = error;
    for (final middleware in middlewares.reversed) {
      final onError = middleware.onError;
      if (onError == null) continue;
      final replacement = await onError(request, effectiveError, stackTrace);
      if (replacement != null) {
        effectiveError = replacement;
      }
    }
    Error.throwWithStackTrace(effectiveError, stackTrace);
  }
}
