import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../common/transport_cancellation.dart';
import '../common/transport_diagnostics.dart';
import '../common/transport_exception.dart';
import '../common/transport_retry.dart';
import 'dio_cancellation_adapter.dart';
import 'dio_response_stream.dart';
import 'transport_client.dart';

final class DioTransportClient implements TransportClient {
  final Dio _dio;
  final Logger _logger;
  final TransportDiagnostics? _diagnostics;
  final TransportRetryPolicy _retryPolicy;

  static final Object _retryDelaySentinel = Object();

  DioTransportClient({
    Dio? dio,
    Logger? logger,
    TransportDiagnostics? diagnostics,
    TransportRetryPolicy retryPolicy = const TransportRetryPolicy(),
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                validateStatus: (_) => true,
              ),
            ),
        _logger = logger ?? Logger('DioTransportClient'),
        _diagnostics = diagnostics,
        _retryPolicy = retryPolicy;

  /// Exposes the underlying Dio instance for compatibility adapters.
  Dio get dio => _dio;

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
            method: _toDioMethod(request.method),
            headers: request.headers,
            responseType: _toDioResponseType(request.responseType),
            sendTimeout: request.timeout,
            receiveTimeout: request.timeout,
          ),
        );

        final headers = _flattenHeaders(response.headers.map);

        if (!_isSuccessStatus(response.statusCode)) {
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
          response: _createResponseInfo(
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
            method: _toDioMethod(request.method),
            headers: request.headers,
            responseType: ResponseType.stream,
            sendTimeout: request.timeout,
            receiveTimeout: request.timeout,
          ),
        );

        final headers = _flattenHeaders(response.headers.map);

        if (!_isSuccessStatus(response.statusCode)) {
          throw TransportHttpException(
            'HTTP stream request failed with status ${response.statusCode}',
            statusCode: response.statusCode ?? 0,
            headers: headers,
            responseBody: await _readErrorBody(response.data),
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
          response: _createResponseInfo(
            statusCode: result.statusCode,
            headers: result.headers,
            body: responseBody,
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
    final requestInfo = _createRequestInfo(
      request,
      isStreaming: isStreaming,
    );
    for (var attempt = 1; true; attempt++) {
      final startedAt = DateTime.now();
      _emitDiagnostics(
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
        _emitDiagnostics(
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
        final mapped = await _mapDioException(
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
  }) async {
    final finishedAt = DateTime.now();
    _emitDiagnostics(
      TransportDiagnosticsEvent(
        kind: TransportDiagnosticsEventKind.requestFailure,
        request: requestInfo,
        response: _responseInfoFromError(error),
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
    if (!_retryPolicy.shouldRetry(retryContext)) {
      return false;
    }

    await _waitForRetryDelay(
      _retryPolicy.delayFor(retryContext),
      request.cancellation,
    );
    return true;
  }

  TransportDiagnosticsRequestInfo _createRequestInfo(
    TransportRequest request, {
    required bool isStreaming,
  }) {
    final headerNames = request.headers.keys.toList(growable: false)..sort();
    return TransportDiagnosticsRequestInfo(
      uri: request.uri,
      method: request.method,
      responseType: request.responseType,
      timeout: request.timeout,
      isStreaming: isStreaming,
      hasBody: request.body != null,
      bodyType: request.body?.runtimeType.toString(),
      headerNames: headerNames,
    );
  }

  TransportDiagnosticsResponseInfo _createResponseInfo({
    required int statusCode,
    required Map<String, String> headers,
    required Object? body,
  }) {
    final headerNames = headers.keys.toList(growable: false)..sort();
    return TransportDiagnosticsResponseInfo(
      statusCode: statusCode,
      headerNames: headerNames,
      bodyType: body?.runtimeType.toString(),
    );
  }

  TransportDiagnosticsResponseInfo? _responseInfoFromError(Object error) {
    if (error is! TransportHttpException) {
      return null;
    }

    return _createResponseInfo(
      statusCode: error.statusCode,
      headers: error.headers,
      body: error.responseBody,
    );
  }

  void _emitDiagnostics(TransportDiagnosticsEvent event) {
    _diagnostics?.onEvent(event);
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

  Future<Object> _mapDioException(
    DioException error, {
    required Uri uri,
  }) async {
    if (CancelToken.isCancel(error)) {
      return TransportCancelledException(error.message);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TransportTimeoutException(
          error.message ?? 'Transport request timed out',
          uri: uri,
          cause: error,
        );
      case DioExceptionType.badResponse:
        return TransportHttpException(
          error.message ?? 'HTTP request failed',
          statusCode: error.response?.statusCode ?? 0,
          headers: _flattenHeaders(
            error.response?.headers.map ?? const <String, List<String>>{},
          ),
          responseBody: await _readErrorBody(error.response?.data),
          uri: uri,
          cause: error,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return TransportNetworkException(
          error.message ?? 'Transport network error',
          uri: uri,
          cause: error,
        );
      case DioExceptionType.cancel:
        return TransportCancelledException(error.message);
    }
  }

  Future<Object?> _readErrorBody(Object? data) async {
    if (data is ResponseBody) {
      try {
        final content = await collectDioResponseTextBody(data);
        if (content.isEmpty) {
          return null;
        }
        return content;
      } catch (error, stackTrace) {
        _logger.fine('Failed to read error response body: $error');
        _logger.finer(stackTrace.toString());
        return null;
      }
    }

    return data;
  }

  static ResponseType _toDioResponseType(TransportResponseType responseType) {
    return switch (responseType) {
      TransportResponseType.json => ResponseType.json,
      TransportResponseType.plainText => ResponseType.plain,
      TransportResponseType.bytes => ResponseType.bytes,
    };
  }

  static String _toDioMethod(TransportMethod method) {
    return switch (method) {
      TransportMethod.get => 'GET',
      TransportMethod.post => 'POST',
      TransportMethod.put => 'PUT',
      TransportMethod.patch => 'PATCH',
      TransportMethod.delete => 'DELETE',
    };
  }

  static Map<String, String> _flattenHeaders(
      Map<String, List<String>> headers) {
    return Map<String, String>.fromEntries(
      headers.entries.map(
        (entry) => MapEntry(entry.key, entry.value.join(',')),
      ),
    );
  }

  static bool _isSuccessStatus(int? statusCode) {
    return statusCode != null && statusCode >= 200 && statusCode < 300;
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
