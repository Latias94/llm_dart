import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../common/transport_cancellation.dart';
import '../common/transport_diagnostics.dart';
import '../common/transport_exception.dart';
import 'transport_client.dart';

final class DioTransportClient implements TransportClient {
  final Dio _dio;
  final Logger _logger;
  final TransportDiagnostics? _diagnostics;

  DioTransportClient({
    Dio? dio,
    Logger? logger,
    TransportDiagnostics? diagnostics,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                validateStatus: (_) => true,
              ),
            ),
        _logger = logger ?? Logger('DioTransportClient'),
        _diagnostics = diagnostics;

  /// Exposes the underlying Dio instance for compatibility adapters.
  Dio get dio => _dio;

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    final requestInfo = _createRequestInfo(
      request,
      isStreaming: false,
    );
    final startedAt = DateTime.now();
    _emitDiagnostics(
      TransportDiagnosticsEvent(
        kind: TransportDiagnosticsEventKind.requestStart,
        request: requestInfo,
        timestamp: startedAt,
      ),
    );

    try {
      request.cancellation?.throwIfCancelled();
      final cancelToken = _bindCancellation(request.cancellation);
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
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestSuccess,
          request: requestInfo,
          response: _createResponseInfo(
            statusCode: result.statusCode,
            headers: result.headers,
            body: result.body,
          ),
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      return result;
    } on DioException catch (error) {
      final mapped = await _mapDioException(
        error,
        uri: request.uri,
      );
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestFailure,
          request: requestInfo,
          response: _responseInfoFromError(mapped),
          error: mapped,
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      throw mapped;
    } on TransportException catch (error) {
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestFailure,
          request: requestInfo,
          response: _responseInfoFromError(error),
          error: error,
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      rethrow;
    } catch (error) {
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestFailure,
          request: requestInfo,
          error: error,
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<StreamingTransportResponse> sendStream(
    TransportRequest request,
  ) async {
    final requestInfo = _createRequestInfo(
      request,
      isStreaming: true,
    );
    final startedAt = DateTime.now();
    _emitDiagnostics(
      TransportDiagnosticsEvent(
        kind: TransportDiagnosticsEventKind.requestStart,
        request: requestInfo,
        timestamp: startedAt,
      ),
    );

    try {
      request.cancellation?.throwIfCancelled();
      final cancelToken = _bindCancellation(request.cancellation);
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
      final result = switch (responseBody) {
        ResponseBody() => StreamingTransportResponse(
            statusCode: response.statusCode ?? 0,
            headers: headers,
            stream: responseBody.stream,
          ),
        Stream<List<int>>() => StreamingTransportResponse(
            statusCode: response.statusCode ?? 0,
            headers: headers,
            stream: responseBody,
          ),
        _ => throw TransportResponseFormatException(
            'Expected a streaming response body but received ${responseBody.runtimeType}',
            uri: request.uri,
          ),
      };

      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestSuccess,
          request: requestInfo,
          response: _createResponseInfo(
            statusCode: result.statusCode,
            headers: result.headers,
            body: responseBody,
          ),
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      return result;
    } on DioException catch (error) {
      final mapped = await _mapDioException(
        error,
        uri: request.uri,
      );
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestFailure,
          request: requestInfo,
          response: _responseInfoFromError(mapped),
          error: mapped,
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      throw mapped;
    } on TransportException catch (error) {
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestFailure,
          request: requestInfo,
          response: _responseInfoFromError(error),
          error: error,
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      rethrow;
    } catch (error) {
      _emitDiagnostics(
        TransportDiagnosticsEvent(
          kind: TransportDiagnosticsEventKind.requestFailure,
          request: requestInfo,
          error: error,
          timestamp: DateTime.now(),
          duration: DateTime.now().difference(startedAt),
        ),
      );
      rethrow;
    }
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

  CancelToken? _bindCancellation(TransportCancellation? cancellation) {
    if (cancellation == null) {
      return null;
    }

    final cancelToken = CancelToken();
    unawaited(
      cancellation.whenCancelled.then((reason) {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel(reason);
        }
      }),
    );
    return cancelToken;
  }

  Future<TransportException> _mapDioException(
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
        final chunks = await data.stream.toList();
        final bytes = chunks.expand((chunk) => chunk).toList();
        if (bytes.isEmpty) {
          return null;
        }
        return utf8.decode(bytes, allowMalformed: true);
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
