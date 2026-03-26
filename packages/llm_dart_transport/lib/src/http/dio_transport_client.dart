import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../common/transport_cancellation.dart';
import '../common/transport_exception.dart';
import 'transport_client.dart';

final class DioTransportClient implements TransportClient {
  final Dio _dio;
  final Logger _logger;

  DioTransportClient({
    Dio? dio,
    Logger? logger,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                validateStatus: (_) => true,
              ),
            ),
        _logger = logger ?? Logger('DioTransportClient');

  @override
  Future<TransportResponse> send(TransportRequest request) async {
    request.cancellation?.throwIfCancelled();

    final cancelToken = _bindCancellation(request.cancellation);

    try {
      final response = await _dio.requestUri<Object?>(
        request.uri,
        data: request.body,
        cancelToken: cancelToken,
        options: Options(
          method: _toDioMethod(request.method),
          headers: request.headers,
          responseType: _toDioResponseType(request.responseType),
          connectTimeout: request.timeout,
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

      return TransportResponse(
        statusCode: response.statusCode ?? 0,
        headers: headers,
        body: response.data,
      );
    } on DioException catch (error) {
      throw await _mapDioException(
        error,
        uri: request.uri,
      );
    }
  }

  @override
  Future<StreamingTransportResponse> sendStream(TransportRequest request) async {
    request.cancellation?.throwIfCancelled();

    final cancelToken = _bindCancellation(request.cancellation);

    try {
      final response = await _dio.requestUri<Object?>(
        request.uri,
        data: request.body,
        cancelToken: cancelToken,
        options: Options(
          method: _toDioMethod(request.method),
          headers: request.headers,
          responseType: ResponseType.stream,
          connectTimeout: request.timeout,
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
      if (responseBody is ResponseBody) {
        return StreamingTransportResponse(
          statusCode: response.statusCode ?? 0,
          headers: headers,
          stream: responseBody.stream,
        );
      }

      if (responseBody is Stream<List<int>>) {
        return StreamingTransportResponse(
          statusCode: response.statusCode ?? 0,
          headers: headers,
          stream: responseBody,
        );
      }

      throw TransportResponseFormatException(
        'Expected a streaming response body but received ${responseBody.runtimeType}',
        uri: request.uri,
      );
    } on DioException catch (error) {
      throw await _mapDioException(
        error,
        uri: request.uri,
      );
    }
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

  static Map<String, String> _flattenHeaders(Map<String, List<String>> headers) {
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
