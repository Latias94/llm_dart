part of 'dio_error_handler.dart';

/// HTTP error mapper utility
class HttpErrorMapper {
  /// Map HTTP status code to appropriate LLM error
  static LLMError mapStatusCode(
    int statusCode,
    String message, [
    Map<String, dynamic>? responseData,
  ]) {
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
        return ServerError('Gateway Timeout: $message', statusCode: statusCode);
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

  /// Map specific error types based on error content
  static LLMError? _mapSpecificError(
    String message,
    Map<String, dynamic> responseData,
  ) {
    final errorField = responseData['error'];

    Map<String, dynamic>? error;
    String? errorType;
    String? errorCode;

    if (errorField is Map<String, dynamic>) {
      error = errorField;
      errorType = error['type'] as String?;
      errorCode = error['code']?.toString();
    } else if (errorField is String) {
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
      return null;
    } else {
      return null;
    }

    if (errorType == 'content_filter' ||
        errorCode == 'content_filter' ||
        message.toLowerCase().contains('content policy') ||
        message.toLowerCase().contains('content filter')) {
      return ContentFilterError(message, filterType: errorType ?? errorCode);
    }

    if (errorType == 'model_not_found' ||
        errorCode == 'model_not_found' ||
        message.toLowerCase().contains('model') &&
            message.toLowerCase().contains('not found')) {
      final model = error['model'] as String? ??
          responseData['model'] as String? ??
          'unknown';
      return ModelNotAvailableError(model);
    }

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

  /// Extract retry-after duration from response headers
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
