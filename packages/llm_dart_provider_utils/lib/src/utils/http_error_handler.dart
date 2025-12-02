import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';

/// Dio error handler utility for consistent error handling across providers.
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
          final errorInfo = await _extractErrorInfo(data);
          final errorMessage = errorInfo.message ?? 'Unknown error';

          return HttpErrorMapper.mapStatusCode(
            statusCode,
            errorMessage,
            errorInfo.responseData,
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

class _ErrorInfo {
  final String? message;
  final Map<String, dynamic>? responseData;

  const _ErrorInfo(this.message, this.responseData);
}

Future<_ErrorInfo> _extractErrorInfo(dynamic data) async {
  if (data == null) {
    return const _ErrorInfo(null, null);
  }

  if (data is Map<String, dynamic>) {
    String errorMessage = 'Unknown error';
    final error = data['error'];
    if (error is Map<String, dynamic>) {
      errorMessage = error['message']?.toString() ?? data.toString();
    } else if (error is String) {
      errorMessage = error;
    } else {
      errorMessage = data.toString();
    }
    return _ErrorInfo(errorMessage, data);
  }

  if (data is ResponseBody) {
    try {
      final chunks = await data.stream.toList();
      final bytes = chunks.expand((c) => c).toList();
      final content = utf8.decode(bytes);

      if (content.isEmpty) {
        return const _ErrorInfo(null, null);
      }

      try {
        final json = jsonDecode(content);
        if (json is Map<String, dynamic>) {
          String errorMessage = 'Unknown error';
          final error = json['error'];
          if (error is Map<String, dynamic>) {
            errorMessage = error['message']?.toString() ?? content;
          } else if (error is String) {
            errorMessage = error;
          } else {
            errorMessage = content;
          }
          return _ErrorInfo(errorMessage, json);
        }
      } catch (_) {
        // Not JSON, fall through and use raw content.
      }

      return _ErrorInfo(content, null);
    } catch (e) {
      return _ErrorInfo('Failed to read error response: $e', null);
    }
  }

  // Fallback for other data types (String, List<int>, etc.).
  return _ErrorInfo(data.toString(), null);
}

/// HTTP error mapper utility.
class HttpErrorMapper {
  /// Map HTTP status code to appropriate LLM error.
  static LLMError mapStatusCode(
    int statusCode,
    String message, [
    Map<String, dynamic>? responseData,
  ]) {
    // Check for specific error types based on response data.
    if (responseData != null) {
      final specificError = _mapSpecificError(message, responseData);
      if (specificError != null) return specificError;
    }

    switch (statusCode) {
      case 400:
        return InvalidRequestError(message);
      case 401:
        return AuthError(message);
      case 402:
        // DeepSeek API specific: Insufficient Balance.
        return QuotaExceededError(message, quotaType: 'credits');
      case 403:
        return AuthError('Forbidden: $message');
      case 404:
        final model = responseData?['model'] as String?;
        return ModelNotAvailableError(model ?? 'unknown');
      case 422:
        return InvalidRequestError('Validation error: $message');
      case 429:
        final retryAfter = responseData?['retry_after'] as int?;
        final remaining = responseData?['remaining_requests'] as int?;
        return RateLimitError(
          message,
          retryAfter: retryAfter != null ? Duration(seconds: retryAfter) : null,
          remainingRequests: remaining,
        );
      case 500:
        return ServerError(message, statusCode: statusCode);
      case 502:
        return ServerError('Bad Gateway: $message', statusCode: statusCode);
      case 503:
        return ServerError(
          'Service Unavailable: $message',
          statusCode: statusCode,
        );
      case 504:
        return ServerError(
          'Gateway Timeout: $message',
          statusCode: statusCode,
        );
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return HttpError(message);
        } else if (statusCode >= 500) {
          return ServerError(message, statusCode: statusCode);
        } else {
          return HttpError(message);
        }
    }
  }

  /// Map specific error types based on error content.
  static LLMError? _mapSpecificError(
    String message,
    Map<String, dynamic> responseData,
  ) {
    final errorField = responseData['error'];

    // Handle both Map and String error formats.
    Map<String, dynamic>? error;
    String? errorType;
    String? errorCode;

    if (errorField is Map<String, dynamic>) {
      error = errorField;
      errorType = error['type'] as String?;
      // Error code can be string or numeric; normalize to string.
      errorCode = error['code']?.toString();
    } else if (errorField is String) {
      // If error is a string, use it as the error message
      // and try to extract type/code from the message.
      if (errorField.toLowerCase().contains('authentication') ||
          errorField.toLowerCase().contains('api key')) {
        return AuthError(errorField);
      }
      if (errorField.toLowerCase().contains('quota') ||
          errorField.toLowerCase().contains('billing')) {
        return QuotaExceededError(errorField);
      }
      if (errorField.toLowerCase().contains('model') &&
          errorField.toLowerCase().contains('not found')) {
        return ModelNotAvailableError('unknown');
      }
      // For other string errors, return null to use default handling.
      return null;
    } else {
      return null;
    }

    // Content filter errors.
    if (errorType == 'content_filter' ||
        errorCode == 'content_filter' ||
        message.toLowerCase().contains('content policy') ||
        message.toLowerCase().contains('content filter')) {
      return ContentFilterError(message, filterType: errorType ?? errorCode);
    }

    // Model not available errors.
    if (errorType == 'model_not_found' ||
        errorCode == 'model_not_found' ||
        (message.toLowerCase().contains('model') &&
            message.toLowerCase().contains('not found'))) {
      final model = error['model'] as String? ??
          responseData['model'] as String? ??
          'unknown';
      return ModelNotAvailableError(model);
    }

    // Quota exceeded errors.
    if (errorType == 'insufficient_quota' ||
        errorCode == 'insufficient_quota' ||
        message.toLowerCase().contains('quota') ||
        message.toLowerCase().contains('billing')) {
      String? quotaType;
      if (message.toLowerCase().contains('token')) {
        quotaType = 'tokens';
      } else if (message.toLowerCase().contains('request')) {
        quotaType = 'requests';
      } else if (message.toLowerCase().contains('credit')) {
        quotaType = 'credits';
      }

      return QuotaExceededError(message, quotaType: quotaType);
    }

    return null;
  }

  /// Extract retry-after duration from response headers.
  static Duration? extractRetryAfter(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    final retryAfter = headers['retry-after'] ?? headers['Retry-After'];
    if (retryAfter == null) return null;

    if (retryAfter is int) {
      return Duration(seconds: retryAfter);
    } else if (retryAfter is String) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }

    return null;
  }
}
