import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:llm_dart_core/llm_dart_core.dart';

/// Dio error handler utility for consistent error handling across providers.
///
/// This is intentionally located in `llm_dart_provider_utils` (not `llm_dart_core`)
/// because it depends on Dio types.
class DioErrorHandler {
  /// Handle Dio errors and convert to appropriate LLM errors.
  static Future<LLMError> handleDioError(
    DioException e,
    String providerName,
  ) async {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('${e.message}');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (statusCode != null) {
          String errorMessage = 'Unknown error';
          Map<String, dynamic>? responseData;

          if (data is Map<String, dynamic>) {
            responseData = data;
            final error = data['error'];
            if (error is Map<String, dynamic>) {
              errorMessage = error['message']?.toString() ?? data.toString();
            } else if (error is String) {
              errorMessage = error;
            } else {
              errorMessage = data.toString();
            }
          } else if (data is ResponseBody) {
            try {
              final bytes = await data.stream.toList();
              final concatenated = bytes.expand((x) => x).toList();
              final content = utf8.decode(concatenated);

              try {
                final jsonData = jsonDecode(content) as Map<String, dynamic>;
                responseData = jsonData;
                final error = jsonData['error'];
                if (error is Map<String, dynamic>) {
                  errorMessage = error['message']?.toString() ?? content;
                } else if (error is String) {
                  errorMessage = error;
                } else {
                  errorMessage = content;
                }
              } catch (_) {
                errorMessage = content;
              }
            } catch (streamError) {
              errorMessage = 'Failed to read error response: $streamError';
            }
          } else if (data != null) {
            errorMessage = data.toString();
          }

          return HttpErrorMapper.mapStatusCode(
            statusCode,
            errorMessage,
            responseData,
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
}
