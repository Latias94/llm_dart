import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../common/transport_cancellation.dart';
import '../common/transport_diagnostics.dart';
import '../common/transport_exception.dart';
import '../common/transport_retry.dart';
import 'dio_cancellation_adapter.dart';
import 'dio_response_stream.dart';
import 'dio_transport_diagnostics_support.dart';
import 'dio_transport_error_mapper.dart';
import 'dio_transport_response_support.dart';
import 'transport_client.dart';

final class DioTransportClient implements TransportClient {
  final Dio _dio;
  final Logger _logger;
  final TransportDiagnostics? _diagnostics;
  final TransportDiagnosticsOptions _diagnosticsOptions;
  final TransportRetryPolicy _retryPolicy;
  final DioTransportResponseSupport _responseSupport =
      const DioTransportResponseSupport();

  static final Object _retryDelaySentinel = Object();

  DioTransportClient({
    Dio? dio,
    Logger? logger,
    TransportDiagnostics? diagnostics,
    TransportDiagnosticsOptions diagnosticsOptions =
        const TransportDiagnosticsOptions(),
    TransportRetryPolicy retryPolicy = const TransportRetryPolicy(),
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                validateStatus: (_) => true,
              ),
            ),
        _logger = logger ?? Logger('DioTransportClient'),
        _diagnostics = diagnostics,
        _diagnosticsOptions = diagnosticsOptions,
        _retryPolicy = retryPolicy;

  /// Exposes the underlying Dio instance for compatibility adapters.
  Dio get dio => _dio;

  late final DioTransportDiagnosticsSupport _diagnosticsSupport =
      DioTransportDiagnosticsSupport(
    diagnostics: _diagnostics,
    options: _diagnosticsOptions,
  );
  late final DioTransportErrorMapper _errorMapper = DioTransportErrorMapper(
    logger: _logger,
    responseSupport: _responseSupport,
  );

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    return _executeWithRetry(
      request,
      isStreaming: false,
      sendAttempt: (cancelToken) async {
        final response = await _dio.requestUri<Object?>(
          request.uri,
          data: request.body,
          cancelToken: cancelToken,
          options: Options(
            method: _responseSupport.toDioMethod(request.method),
            headers: request.headers,
            responseType:
                _responseSupport.toDioResponseType(request.responseType),
            connectTimeout: request.timeout,
            sendTimeout: request.timeout,
            receiveTimeout: request.timeout,
          ),
        );

        final headers = _responseSupport.flattenHeaders(response.headers.map);

        if (!_responseSupport.isSuccessStatus(response.statusCode)) {
          throw TransportHttpException(
            'HTTP request failed with status ${response.statusCode}',
            statusCode: response.statusCode ?? 0,
            headers: headers,
            responseBody: response.data,
            uri: request.uri,
          );
        }

        final result = TransportResponse(
          statusCode: response.statusCode ?? 0,
          headers: headers,
          body: response.data,
        );
        return _TransportAttemptSuccess(
          value: result,
          response: _diagnosticsSupport.createResponseInfo(
            statusCode: result.statusCode,
            headers: result.headers,
            body: result.body,
          ),
        );
      },
    );
  }

  @override
  Future<StreamingTransportResponse> sendStream(
    TransportRequest request,
  ) async {
    return _executeWithRetry(
      request,
      isStreaming: true,
      sendAttempt: (cancelToken) async {
        final response = await _dio.requestUri<Object?>(
          request.uri,
          data: request.body,
          cancelToken: cancelToken,
          options: Options(
            method: _responseSupport.toDioMethod(request.method),
            headers: request.headers,
            responseType: ResponseType.stream,
            connectTimeout: request.timeout,
            sendTimeout: request.timeout,
            receiveTimeout: request.timeout,
          ),
        );

        final headers = _responseSupport.flattenHeaders(response.headers.map);

        if (!_responseSupport.isSuccessStatus(response.statusCode)) {
          throw TransportHttpException(
            'HTTP stream request failed with status ${response.statusCode}',
            statusCode: response.statusCode ?? 0,
            headers: headers,
            responseBody: await _errorMapper.readErrorBody(response.data),
            uri: request.uri,
          );
        }

        final responseBody = response.data;
        final result = StreamingTransportResponse(
          statusCode: response.statusCode ?? 0,
          headers: headers,
          stream: extractDioResponseByteStream(
            responseBody,
            sourceName: 'response body',
            uri: request.uri,
          ),
        );

        return _TransportAttemptSuccess(
          value: result,
          response: _diagnosticsSupport.createResponseInfo(
            statusCode: result.statusCode,
            headers: result.headers,
            body: responseBody,
            includeBody: false,
          ),
        );
      },
    );
  }

  Future<T> _executeWithRetry<T>(
    TransportRequest request, {
    required bool isStreaming,
    required Future<_TransportAttemptSuccess<T>> Function(
      CancelToken? cancelToken,
    ) sendAttempt,
  }) async {
    final retryPolicy = _effectiveRetryPolicy(request);
    final requestInfo = _diagnosticsSupport.createRequestInfo(
      request,
      isStreaming: isStreaming,
      retryPolicy: retryPolicy,
    );
    for (var attempt = 1; true; attempt++) {
      final startedAt = DateTime.now();
      _diagnosticsSupport.emit(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestStart,
          request: requestInfo,
          timestamp: startedAt,
          attempt: attempt,
        ),
      );

      try {
        request.cancellation?.throwIfCancelled();
        final cancelToken = bindDioCancellation(request.cancellation);
        final success = await sendAttempt(cancelToken);
        final finishedAt = DateTime.now();
        _diagnosticsSupport.emit(
          TransportDiagnosticsEvent(
            kind: TransportDiagnosticsEventKind.requestSuccess,
            request: requestInfo,
            response: success.response,
            timestamp: finishedAt,
            duration: finishedAt.difference(startedAt),
            attempt: attempt,
          ),
        );
        return success.value;
      } on DioException catch (error) {
        final mapped = await _errorMapper.mapDioException(
          error,
          uri: request.uri,
        );
        final shouldRetry = await _handleFailure(
          request: request,
          requestInfo: requestInfo,
          isStreaming: isStreaming,
          attempt: attempt,
          startedAt: startedAt,
          error: mapped,
          retryPolicy: retryPolicy,
        );
        if (shouldRetry) {
          continue;
        }
        throw mapped;
      } on TransportException catch (error) {
        final shouldRetry = await _handleFailure(
          request: request,
          requestInfo: requestInfo,
          isStreaming: isStreaming,
          attempt: attempt,
          startedAt: startedAt,
          error: error,
          retryPolicy: retryPolicy,
        );
        if (shouldRetry) {
          continue;
        }
        rethrow;
      } catch (error) {
        final shouldRetry = await _handleFailure(
          request: request,
          requestInfo: requestInfo,
          isStreaming: isStreaming,
          attempt: attempt,
          startedAt: startedAt,
          error: error,
          retryPolicy: retryPolicy,
        );
        if (shouldRetry) {
          continue;
        }
        rethrow;
      }
    }
  }

  Future<bool> _handleFailure({
    required TransportRequest request,
    required TransportDiagnosticsRequestInfo requestInfo,
    required bool isStreaming,
    required int attempt,
    required DateTime startedAt,
    required Object error,
    required TransportRetryPolicy retryPolicy,
  }) async {
    final finishedAt = DateTime.now();
    _diagnosticsSupport.emit(
      TransportDiagnosticsEvent(
        kind: TransportDiagnosticsEventKind.requestFailure,
        request: requestInfo,
        response: _diagnosticsSupport.responseInfoFromError(error),
        error: error,
        timestamp: finishedAt,
        duration: finishedAt.difference(startedAt),
        attempt: attempt,
      ),
    );

    final retryContext = TransportRetryContext(
      request: request,
      attempt: attempt,
      isStreaming: isStreaming,
      error: error,
    );
    if (!retryPolicy.shouldRetry(retryContext)) {
      return false;
    }

    await _waitForRetryDelay(
      retryPolicy.delayFor(retryContext),
      request.cancellation,
    );
    return true;
  }

  TransportRetryPolicy _effectiveRetryPolicy(TransportRequest request) {
    final maxRetries = request.maxRetries;
    if (maxRetries == null) {
      return _retryPolicy;
    }

    return _retryPolicy.withRequestMaxRetries(maxRetries);
  }

  Future<void> _waitForRetryDelay(
    Duration delay,
    TransportCancellation? cancellation,
  ) async {
    if (delay <= Duration.zero) {
      cancellation?.throwIfCancelled();
      return;
    }

    if (cancellation == null) {
      await Future<void>.delayed(delay);
      return;
    }

    final result = await Future.any<Object?>([
      Future<Object?>.delayed(delay, () => _retryDelaySentinel),
      cancellation.whenCancelled,
    ]);
    if (!identical(result, _retryDelaySentinel)) {
      throw TransportCancelledException(result);
    }
  }
}

final class _TransportAttemptSuccess<T> {
  final T value;
  final TransportDiagnosticsResponseInfo response;

  const _TransportAttemptSuccess({
    required this.value,
    required this.response,
  });
}
