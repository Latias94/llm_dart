import 'package:dio/dio.dart';
import 'package:llm_dart_core/llm_dart_core.dart';
import 'package:llm_dart_provider_utils/llm_dart_provider_utils.dart';

/// DeepSeek-specific error handler.
///
/// This class provides specialized error handling for DeepSeek API responses,
/// mapping DeepSeek error codes and messages to appropriate LLM error types.
/// Reference: https://api-docs.deepseek.com/quick_start/error_codes
class DeepSeekErrorHandler {
  /// Handle DeepSeek-specific errors from API responses.
  static LLMError handleDeepSeekError(
    int statusCode,
    String message,
    Map<String, dynamic>? responseData,
  ) {
    final deepSeekError = _mapDeepSeekSpecificError(
      statusCode,
      message,
      responseData,
    );
    if (deepSeekError != null) return deepSeekError;

    return HttpErrorMapper.mapStatusCode(statusCode, message, responseData);
  }

  /// Handle Dio errors specifically for DeepSeek.
  static LLMError handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    if (statusCode != null) {
      String errorMessage = 'DeepSeek API error';

      if (responseData is Map<String, dynamic>) {
        final error = responseData['error'];
        if (error is Map<String, dynamic>) {
          errorMessage = error['message']?.toString() ?? errorMessage;
        } else if (error is String) {
          errorMessage = error;
        }
      } else if (responseData is String) {
        errorMessage = responseData;
      }

      return handleDeepSeekError(
        statusCode,
        errorMessage,
        responseData is Map<String, dynamic> ? responseData : null,
      );
    }

    return DioErrorHandler.handleDioError(e, 'DeepSeek');
  }

  /// Map DeepSeek-specific error patterns.
  static LLMError? _mapDeepSeekSpecificError(
    int statusCode,
    String message,
    Map<String, dynamic>? responseData,
  ) {
    switch (statusCode) {
      case 400:
        if (message.toLowerCase().contains('invalid format') ||
            message.toLowerCase().contains('invalid request body')) {
          return InvalidRequestError('Invalid request format: $message');
        }
        break;
      case 401:
        if (message.toLowerCase().contains('authentication fails') ||
            message.toLowerCase().contains('wrong api key')) {
          return AuthError(
            'Authentication failed: Check your DeepSeek API key',
          );
        }
        break;
      case 402:
        if (message.toLowerCase().contains('insufficient balance') ||
            message.toLowerCase().contains('run out of balance')) {
          return QuotaExceededError(
            'Insufficient balance: Please top up your DeepSeek account',
            quotaType: 'credits',
          );
        }
        break;
      case 422:
        if (message.toLowerCase().contains('invalid parameters')) {
          return InvalidRequestError('Invalid parameters: $message');
        }
        break;
      case 429:
        if (message.toLowerCase().contains('rate limit') ||
            message.toLowerCase().contains('sending requests too quickly')) {
          return RateLimitError(
            'Rate limit exceeded: Please pace your requests reasonably',
            retryAfter: _extractRetryAfter(responseData),
          );
        }
        break;
      case 500:
        if (message.toLowerCase().contains('server encounters an issue')) {
          return ServerError(
            'DeepSeek server error: Please retry after a brief wait',
            statusCode: statusCode,
          );
        }
        break;
      case 503:
        if (message.toLowerCase().contains('server is overloaded') ||
            message.toLowerCase().contains('high traffic')) {
          return ServerError(
            'DeepSeek server overloaded: Please retry after a brief wait',
            statusCode: statusCode,
          );
        }
        break;
    }

    return null;
  }

  /// Extract retry-after duration from DeepSeek response.
  static Duration? _extractRetryAfter(Map<String, dynamic>? responseData) {
    if (responseData == null) return null;

    final retryAfter = responseData['retry_after'] ??
        responseData['retry-after'] ??
        responseData['Retry-After'];

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

  static bool isModelNotAvailable(String message) {
    final lower = message.toLowerCase();
    return lower.contains('model') &&
        (lower.contains('not found') ||
            lower.contains('not available') ||
            lower.contains('unsupported'));
  }

  static bool isQuotaExceeded(String message) {
    final lower = message.toLowerCase();
    return lower.contains('insufficient balance') ||
        lower.contains('quota') ||
        lower.contains('billing') ||
        lower.contains('run out of balance');
  }

  static bool isRateLimited(String message) {
    final lower = message.toLowerCase();
    return lower.contains('rate limit') ||
        lower.contains('too quickly') ||
        lower.contains('too many requests');
  }

  static bool isServerError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('server error') ||
        lower.contains('server encounters') ||
        lower.contains('server overloaded') ||
        lower.contains('high traffic');
  }
}
