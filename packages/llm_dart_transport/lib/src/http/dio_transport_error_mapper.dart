import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../common/transport_cancellation.dart';
import '../common/transport_exception.dart';
import 'dio_response_stream.dart';
import 'dio_transport_response_support.dart';

final class DioTransportErrorMapper {
  final Logger logger;
  final DioTransportResponseSupport responseSupport;

  const DioTransportErrorMapper({
    required this.logger,
    this.responseSupport = const DioTransportResponseSupport(),
  });

  Future<Object> mapDioException(
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
          headers: responseSupport.flattenHeaders(
            error.response?.headers.map ?? const <String, List<String>>{},
          ),
          responseBody: await readErrorBody(error.response?.data),
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

  Future<Object?> readErrorBody(Object? data) async {
    if (data is ResponseBody) {
      try {
        final content = await collectDioResponseTextBody(data);
        if (content.isEmpty) {
          return null;
        }
        return content;
      } catch (error, stackTrace) {
        logger.fine('Failed to read error response body: $error');
        logger.finer(stackTrace.toString());
        return null;
      }
    }

    return data;
  }
}
