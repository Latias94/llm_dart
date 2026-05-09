import 'package:llm_dart_transport/dio.dart';

import '../llm_error_types.dart';
import 'dio_error_response_details.dart';
import 'http_error_mapper.dart';

export 'http_error_mapper.dart';

/// Dio error handler utility for consistent error handling across providers
class DioErrorHandler {
  /// Handle Dio errors and convert to appropriate LLM errors
  static Future<LLMError> handleDioError(
      DioException e, String providerName) async {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('${e.message}');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (statusCode != null) {
          final details = await extractErrorResponseDetails(data);

          return HttpErrorMapper.mapStatusCode(
            statusCode,
            details.message,
            details.responseData,
          );
        } else {
          return ProviderError('$providerName HTTP error: $data');
        }
      case DioExceptionType.cancel:
        return CancelledError(e.message ?? 'Request cancelled');
      case DioExceptionType.connectionError:
        return HttpError('Connection error: ${e.message}');
      case DioExceptionType.badCertificate:
        return HttpError('SSL certificate error: ${e.message}');
      case DioExceptionType.unknown:
        return GenericError('$providerName request failed: ${e.message}');
    }
  }

  /// Extracts a normalized error message and parsed JSON body when available.
  static Future<({String message, Map<String, dynamic>? responseData})>
      extractErrorResponseDetails(
    dynamic data, {
    String fallbackMessage = 'Unknown error',
    String? Function(Map<String, dynamic> responseData)? mapMessageExtractor,
  }) async {
    return extractDioErrorResponseDetails(
      data,
      fallbackMessage: fallbackMessage,
      mapMessageExtractor: mapMessageExtractor,
    );
  }
}
