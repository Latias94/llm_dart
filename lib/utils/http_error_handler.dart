import 'package:dio/dio.dart';

import '../core/llm_error.dart';

/// Maps HTTP status codes to high-level LLMError types.
class HttpErrorMapper {
  static LLMError mapStatusCode(
    int statusCode,
    String message,
    Map<String, dynamic>? responseData,
  ) {
    // Normalize message
    final normalized = message.trim().isEmpty ? '$statusCode' : message.trim();

    if (statusCode == 400 || statusCode == 422) {
      return InvalidRequestError(normalized);
    }

    if (statusCode == 401 || statusCode == 403) {
      return AuthError(normalized);
    }

    if (statusCode == 404) {
      return NotFoundError(normalized);
    }

    if (statusCode == 429) {
      return RateLimitError(
        normalized,
        // Some providers include retry information in the response body
        retryAfter: _extractRetryAfter(responseData),
      );
    }

    if (statusCode >= 500 && statusCode < 600) {
      return ServerError(
        normalized,
        statusCode: statusCode,
      );
    }

    // Fallback: treat as generic provider error
    return ProviderError(normalized);
  }

  static Duration? _extractRetryAfter(Map<String, dynamic>? responseData) {
    if (responseData == null) return null;

    final retryAfter = responseData['retry_after'] ??
        responseData['retry-after'] ??
        responseData['Retry-After'];

    if (retryAfter is int) {
      return Duration(seconds: retryAfter);
    }

    if (retryAfter is String) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }

    return null;
  }
}

/// Centralized handler for converting DioException into LLMError.
class DioErrorHandler {
  static LLMError handleDioError(DioException e, String providerName) {
    final prefix = providerName.isNotEmpty ? '$providerName: ' : '';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutError('${prefix}Request timeout: ${e.message}');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (statusCode != null) {
          final message = _extractErrorMessage(statusCode, data) ??
              '${prefix}HTTP $statusCode';
          final responseMap =
              data is Map<String, dynamic> ? data : <String, dynamic>{};
          return HttpErrorMapper.mapStatusCode(
            statusCode,
            message,
            responseMap,
          );
        }

        return ResponseFormatError(
          '${prefix}HTTP error without status code',
          data?.toString() ?? '',
        );

      case DioExceptionType.cancel:
        return CancelledError(e.message ?? '${prefix}Request cancelled');

      case DioExceptionType.connectionError:
        return GenericError('${prefix}Connection error: ${e.message}');

      case DioExceptionType.badCertificate:
        return GenericError('${prefix}SSL certificate error: ${e.message}');

      case DioExceptionType.unknown:
        return GenericError('${prefix}Unknown error: ${e.message}');
    }
  }

  static String? _extractErrorMessage(int statusCode, dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'];

      if (error is Map<String, dynamic>) {
        final message = error['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      } else if (error is String) {
        return error;
      }

      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }

    // Generic fallback
    return 'HTTP $statusCode';
  }
}
